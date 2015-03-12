/*
     File: AVCamCaptureManager.m
 Abstract: Uses the AVCapture classes to capture video and still images.
  Version: 2.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>

@interface AVCamCaptureManager (RecorderDelegate) <AVCamRecorderDelegate>
@end


#pragma mark -
@interface AVCamCaptureManager (InternalUtilityMethods)
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *) frontFacingCamera;
- (AVCaptureDevice *) backFacingCamera;
- (AVCaptureDevice *) audioDevice;
- (NSURL *) tempFileURL;
- (void) removeFile:(NSURL *)outputFileURL;
- (void) copyFileToDocuments:(NSURL *)fileURL;
@end


#pragma mark -
@implementation AVCamCaptureManager

- (id) init
{
    self = [super init];
    if (self != nil) {
		__weak AVCamCaptureManager *weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			BOOL sessionHasDeviceWithMatchingMediaType = NO;
			NSString *deviceMediaType = nil;
			if ([device hasMediaType:AVMediaTypeAudio])
                deviceMediaType = AVMediaTypeAudio;
			else if ([device hasMediaType:AVMediaTypeVideo])
                deviceMediaType = AVMediaTypeVideo;
			
			if (deviceMediaType != nil) {
				for (AVCaptureDeviceInput *input in [[weakSelf session] inputs])
				{
					if ([[input device] hasMediaType:deviceMediaType]) {
						sessionHasDeviceWithMatchingMediaType = YES;
						break;
					}
				}
				
				if (!sessionHasDeviceWithMatchingMediaType) {
					NSError	*error;
					AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
					if ([[weakSelf session] canAddInput:input])
						[[weakSelf session] addInput:input];
				}				
			}
            
			if ([[weakSelf delegate] respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[[weakSelf delegate] captureManagerDeviceConfigurationChanged:weakSelf];
			}			
        };
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			if ([device hasMediaType:AVMediaTypeAudio]) {
				[[weakSelf session] removeInput:[weakSelf audioInput]];
				[weakSelf setAudioInput:nil];
			}
			else if ([device hasMediaType:AVMediaTypeVideo]) {
				[[weakSelf session] removeInput:[weakSelf videoInput]];
				[weakSelf setVideoInput:nil];
			}
			
			if ([[weakSelf delegate] respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[[weakSelf delegate] captureManagerDeviceConfigurationChanged:weakSelf];
			}			
        };
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [self setDeviceConnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:deviceConnectedBlock]];
        [self setDeviceDisconnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:deviceDisconnectedBlock]];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//		[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
		_orientation = AVCaptureVideoOrientationPortrait;
    }
    
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:[self deviceConnectedObserver]];
    [notificationCenter removeObserver:[self deviceDisconnectedObserver]];
//	[notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[self session] stopRunning];
}

- (BOOL) setupSession
{
    BOOL success = NO;
    
	// Set torch and flash mode to auto
	if ([[self backFacingCamera] hasFlash]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isFlashModeSupported:AVCaptureFlashModeAuto]) {
				[[self backFacingCamera] setFlashMode:AVCaptureFlashModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
	if ([[self backFacingCamera] hasTorch]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isTorchModeSupported:AVCaptureTorchModeAuto]) {
				[[self backFacingCamera] setTorchMode:AVCaptureTorchModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
	
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    AVCaptureDeviceInput *newAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    
	
    // Setup the still image file output
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
    [newStillImageOutput setOutputSettings:outputSettings];
    
    
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    
    
    // Add inputs and output to the capture session
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    if ([newCaptureSession canAddInput:newAudioInput]) {
        [newCaptureSession addInput:newAudioInput];
    }
    if ([newCaptureSession canAddOutput:newStillImageOutput]) {
        [newCaptureSession addOutput:newStillImageOutput];
    }
    
    [self setStillImageOutput:newStillImageOutput];
    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setSession:newCaptureSession];
    
    
	// Set up the movie file output
    NSURL *outputFileURL = [self tempFileURL];
    AVCamRecorder *newRecorder = [[AVCamRecorder alloc] initWithSession:[self session] outputFileURL:outputFileURL];
    [newRecorder setDelegate:self];
	
	// Send an error to the delegate if video recording is unavailable
	if (![newRecorder recordsVideo] && [newRecorder recordsAudio]) {
		NSString *localizedDescription = NSLocalizedString(@"Video recording unavailable", @"Video recording unavailable description");
		NSString *localizedFailureReason = NSLocalizedString(@"Movies recorded on this device will only contain audio. They will be accessible through iTunes file sharing.", @"Video recording unavailable failure reason");
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: localizedDescription, 
								   NSLocalizedFailureReasonErrorKey: localizedFailureReason};
		NSError *noVideoError = [NSError errorWithDomain:@"AVCam" code:0 userInfo:errorDict];
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:noVideoError];
		}
	}
	
	[self setRecorder:newRecorder];
	
    success = YES;
    
    return success;
}

- (void) startRecording
{
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns
		// to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library
		// when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error:
		// after the recorded file has been saved.
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    }
    
    [self removeFile:[[self recorder] outputFileURL]];
    [[self recorder] startRecordingWithOrientation:self.orientation];
}

- (void) stopRecording
{
    [[self recorder] stopRecording];
}

- (UIImage *)normalizedImageFromImage:(UIImage *)capturedImage {
    if (capturedImage.imageOrientation == UIImageOrientationUp) return capturedImage;
    
    UIGraphicsBeginImageContextWithOptions(capturedImage.size, NO, capturedImage.scale);
    [capturedImage drawInRect:(CGRect){0, 0, capturedImage.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (void) captureStillImage
{
    AVCaptureConnection *stillImageConnection = [[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo];
    if ([stillImageConnection isVideoOrientationSupported])
        [stillImageConnection setVideoOrientation:self.orientation];
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
															 
															 ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
																 if (error) {
                                                                     if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                                                                         [[self delegate] captureManager:self didFailWithError:error];
                                                                         }
																 }
															 };
															 
															 if (imageDataSampleBuffer != NULL) {
																 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
																 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
																 
                                                                 UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                                 
                                                                 
                                                                 CGRect rect = CGRectMake(0,
                                                                                   (image.size.height - image.size.width) / 2,
                                                                                   image.size.width,
                                                                                   image.size.width);
                                                                 
                                                                 UIImage *imageNormalized = [self normalizedImageFromImage:image];
                                                                 
                                                                 CGImageRef imageRef = CGImageCreateWithImageInRect([imageNormalized CGImage], rect);
                                                                 UIImage *result = [UIImage imageWithCGImage:imageRef 
                                                                                                       scale:1
                                                                                                 orientation:UIImageOrientationUp];
                                                                 CGImageRelease(imageRef);
                                                                 
                                                                 self.imageCapturedFromSession = result;
																 [library writeImageToSavedPhotosAlbum:[result CGImage]
																						   orientation:(ALAssetOrientation)[imageNormalized imageOrientation]
																					   completionBlock:completionBlock];
																 
															 }
															 else
																 completionBlock(nil, error);
															 
															 if ([[self delegate] respondsToSelector:@selector(captureManagerStillImageCaptured:)]) {
																 [[self delegate] captureManagerStillImageCaptured:self];
															 }
                                                         }];
}

// Toggle between the front and back camera, if both are present.
- (BOOL) toggleCamera
{
    BOOL success = NO;
    
    if ([self cameraCount] > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
        else
            goto bail;
        
        if (newVideoInput != nil) {
            [[self session] beginConfiguration];
            [[self session] removeInput:[self videoInput]];
            if ([[self session] canAddInput:newVideoInput]) {
                [[self session] addInput:newVideoInput];
                [self setVideoInput:newVideoInput];
            } else {
                [[self session] addInput:[self videoInput]];
            }
            [[self session] commitConfiguration];
            success = YES;
        } else if (error) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }
    }
    
bail:
    return success;
}


#pragma mark Device Counts
- (NSUInteger) cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}


#pragma mark Camera Properties
// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void) autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }        
    }
}

// Switch to continuous auto focus mode at the specified point
- (void) continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
	
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
		NSError *error;
		if ([device lockForConfiguration:&error]) {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}

@end


#pragma mark -
@implementation AVCamCaptureManager (InternalUtilityMethods)

// Keep track of current device orientation so it can be applied to movie recordings and still image captures
- (void)deviceOrientationDidChange
{
    self.orientation = AVCaptureVideoOrientationPortrait;
//	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
//    
//	if (deviceOrientation == UIDeviceOrientationPortrait)
//		self.orientation = AVCaptureVideoOrientationPortrait;
//	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
//		self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
//	
//	// AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
//	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
//		self.orientation = AVCaptureVideoOrientationLandscapeRight;
//	else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
//		self.orientation = AVCaptureVideoOrientationLandscapeLeft;
	
	// Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
}

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// Find and return an audio device, returning nil if one is not found
- (AVCaptureDevice *) audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return devices[0];
    }
    return nil;
}

- (NSURL *) tempFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }            
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
	NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:error];
		}
	}
}	

@end


#pragma mark -
@implementation AVCamCaptureManager (RecorderDelegate)

-(void)recorderRecordingDidBegin:(AVCamRecorder *)recorder
{
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingBegan:)]) {
        [[self delegate] captureManagerRecordingBegan:self];
    }
}

-(void)recorder:(AVCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error
{
	if ([[self recorder] recordsAudio] && ![[self recorder] recordsVideo]) {
		// If the file was created on a device that doesn't support video recording, it can't be saved to the assets 
		// library. Instead, save it in the app's Documents directory, whence it can be copied from the device via
		// iTunes file sharing.
		[self copyFileToDocuments:outputFileURL];

		if ([[UIDevice currentDevice] isMultitaskingSupported]) {
			[[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
		}		

//		if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:)]) {
//			[[self delegate] captureManagerRecordingFinished:self];
//		}
	}
	else {
        [self cropVideoSquareFromVideoURL:outputFileURL];
	}
}

#pragma mark - Methods to Square Crop

- (void)cropVideoSquareFromVideoURL:(NSURL *)urlVideo {
    
    //load our movie Asset
//    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"OriginalVideo" ofType:@"mov"]]];
    
    AVAsset *asset = [AVAsset assetWithURL:urlVideo];
    
    //create an avassetrack with our asset
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //create a video composition and preset some settings
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //here we are setting its render size to its height x height (Square)
    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    
    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
//    CGFloat yOffset = 80/[UIScreen mainScreen].bounds.size.height * clipVideoTrack.naturalSize.width;
//    
//    NSLog(@"\n\n\n\n\nclipVideoTrack.naturalSize.height : %f\nclipVideoTrack.naturalSize.width : %f\nyOffset : %f\n\n\n\n\n", clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.width, yOffset);
    
    //Here we shift the viewing square up to the TOP of the video so we only see the top
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) / 2);
    
    //Use this code if you want the viewing square to be in the middle of the video
    //CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
    
    //Make sure the square is portrait
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    
    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    //Create an Export Path to store the cropped video
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *exportPath = [documentsPath stringByAppendingFormat:@"/CroppedVideo.mp4"];
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    //Remove any prevouis videos at that path
    [[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];
    
    //Export
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = exportUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             //Call when finished
             NSLog(@"\n\nExporting\n\n");
             [self exportDidFinish:exporter];
         });
     }];
}

//- (void) resizeVideo:(NSURL *)videoPath outputPath:(NSURL *)outputPath
//{
//    
//    NSURL *fullPath = outputPath;
//    
//    NSURL *path = videoPath;
//    
//    
//    NSLog(@"Write Started");
//    
//    NSError *error = nil;
//    
//    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:fullPath fileType:AVFileTypeQuickTimeMovie error:&error];
//    NSParameterAssert(videoWriter);
//    
//    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                   AVVideoCodecH264, AVVideoCodecKey,
//                                   [NSNumber numberWithInt:100], AVVideoWidthKey,
//                                   [NSNumber numberWithInt:100], AVVideoHeightKey,
//                                   nil];
//    
//    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
//                                             assetWriterInputWithMediaType:AVMediaTypeVideo
//                                             outputSettings:videoSettings];
//    
//    NSParameterAssert(videoWriterInput);
//    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
//    
//    videoWriterInput.expectsMediaDataInRealTime = NO;
//    
//    [videoWriter addInput:videoWriterInput];
//    
//    
//    
//    
//    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:path options:nil];
//    NSError *aerror = nil;
//    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
//    
//    
//    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
//    
//    NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    
//    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
//    
//    [reader addOutput:asset_reader_output];
//    
//    
//    [videoWriter startWriting];
//    [videoWriter startSessionAtSourceTime:kCMTimeZero];
//    [reader startReading];
//    
//    CMSampleBufferRef buffer;
//    
//    
//    while ( [reader status]==AVAssetReaderStatusReading )
//    {
//        if(![videoWriterInput isReadyForMoreMediaData])
//            continue;
//        
//        buffer = [asset_reader_output copyNextSampleBuffer];
//        
//        
//        NSLog(@"READING");
//        
//        if(buffer)
//            [videoWriterInput appendSampleBuffer:buffer];
//        
//        NSLog(@"WRITTING...");
//        
//        
//    }
//    
//    
//    //Finish the session:
//    [videoWriterInput markAsFinished];
//    NSLog(@"Write Ended");
//    
//}

- (void)exportDidFinish:(AVAssetExportSession*)session
{
    //Play the New Cropped video
//    NSURL *outputURL = session.outputURL;
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:withVideoURL:)]) {
        [[self delegate] captureManagerRecordingFinished:self withVideoURL:session.outputURL];
    }
//    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
//    AVPlayerItem * newPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
//    [self saveVideoInLibraryFromURL:outputURL];
}

//- (void)saveVideoInLibraryFromURL:(NSURL *)urlVideo {
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    [library writeVideoAtPathToSavedPhotosAlbum:urlVideo
//                                completionBlock:^(NSURL *assetURL, NSError *error) {
//                                    NSLog(@"\n\nSaving\n\n");
//                                    if (error) {
//                                        if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
//                                            [[self delegate] captureManager:self didFailWithError:error];
//                                        }
//                                    }
//                                    
//                                    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
//                                        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
//                                    }
//                                    
//                                    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:)]) {
//                                        [[self delegate] captureManagerRecordingFinished:self];
//                                    }
//                                }];
//}

@end
