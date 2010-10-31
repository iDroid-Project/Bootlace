//
//  getFile.h
//  BootlaceV2
//
//  Created by Neonkoala on 14/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "installClass.h"
#import "commonData.h"

@class commonFunctions;
@class installClass;

@interface getFile : NSObject {
	installClass *installInstance;
	
	@private id currentDelegate;
	@private NSMutableData *getFileRequestData;
	@private NSURLConnection *getFileConnection;
	@private NSString *getFileSuggestedName;
	@private NSString *getFilePath;
	@public NSString *getFileURL;
	@public NSString *getFileDir;
	bool getFileWorking;
	
	int dataGot;
	int dataTotal;
	float progress;
}

@property (nonatomic, retain) installClass *installInstance;

@property (nonatomic, retain) NSMutableData *getFileRequestData;
@property (nonatomic, retain) NSString* getFileURL;
@property (nonatomic, retain) NSString *getFileDir;
@property (nonatomic, retain) NSString *getFileSuggestedName;
@property (nonatomic, retain) NSString *getFilePath;
@property (nonatomic, retain) NSURLConnection *getFileConnection;
@property (nonatomic, assign) bool getFileWorking;
@property (nonatomic, assign) int dataGot;
@property (nonatomic, assign) int dataTotal;
@property (nonatomic, assign) float progress;

- (void)setDelegate:(id)new_delegate;
- (id)initWithUrl:(NSString *)fileURL directory:(NSString *)dirPath;
- (void)getFileDownload:(id)delegate;
- (void)getFileAbort;

@end
