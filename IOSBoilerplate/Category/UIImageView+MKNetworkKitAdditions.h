//
//  UIImageView+MKNetworkKitAdditions.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar (@mugunthkumar) on 18/01/13.
//  Copyright (C) 2011-2020 by Steinlogic Consulting and Training Pte Ltd

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <UIKit/UIKit.h>
#import "MKNetworkEngine.h"

// note : 必须事先设置 imageView.frame, 否则不会触发获取图片功能

extern const float kFromCacheAnimationDuration;
extern const float kFreshLoadAnimationDuration;

@class MKNetworkEngine;
@class MKNetworkOperation;

@interface UIImageView (MKNetworkKitAdditions)
 
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image animation:(BOOL) yesOrNo;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image usingEngine:(MKNetworkEngine*) imageCacheEngine animation:(BOOL) yesOrNo;
@end

// 下载 "缩略图" 的专用引擎
@interface DownloadThumbnailNetworkEngine : MKNetworkEngine
+ (DownloadThumbnailNetworkEngine *) sharedInstance;
@end