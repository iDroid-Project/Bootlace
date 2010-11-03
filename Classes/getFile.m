//
//  getFile.m
//  BootlaceV2
//
//  Created by Neonkoala on 14/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "getFile.h"


@implementation getFile

@synthesize installInstance, getFileURL, getFileDir, getFileConnection, getFileRequestData, getFileWorking, getFileSuggestedName, getFilePath, dataTotal, dataGot, progress;

- (id)initWithUrl:(NSString *)fileURL directory:(NSString *)dirPath {
	self = [super init];
	
	if(self) {
		self.getFileURL = fileURL;
		self.getFileDir = dirPath;
	}
	
	return self;
}


- (void)setDelegate:(id)new_delegate {
    currentDelegate = new_delegate;
}	

- (void)getFileDownload:(id)delegate {
	currentDelegate = delegate;
	
	NSURLRequest *getFileRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:getFileURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
	getFileConnection = [[NSURLConnection alloc] initWithRequest:getFileRequest delegate:self];
	
	if(getFileConnection) {
		getFileWorking = YES;
		getFileRequestData = [[NSMutableData data] retain];
	}
}

- (void)getFileAbort {
	if(getFileWorking == YES)
	{
		[getFileConnection cancel];
		[getFileRequestData release];
		getFileWorking = NO;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	commonData* sharedData = [commonData sharedData];	
	
	if ([response respondsToSelector:@selector(statusCode)]) {
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400) {
			if(sharedData.updateStage == 1) {
				sharedData.updateFail = 1;
			} else {
				sharedData.updateFail = 6;
			}
			[getFileConnection cancel];  // stop connecting; no more delegate messages
			DLog(@"NSURLConnection errored with %d", statusCode);
		} else {
			[getFileRequestData setLength:0];
			
			getFileSuggestedName = [response suggestedFilename];
			self.getFilePath = [getFileDir stringByAppendingPathComponent:getFileSuggestedName];
			[getFileRequestData writeToFile:self.getFilePath atomically:YES];
	
			dataTotal = [response expectedContentLength];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	installInstance = [[installClass alloc] init];
	[getFileRequestData appendData:data];
	
	if([getFileRequestData length] > 2621440) {
		NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:self.getFilePath];
		[fh seekToEndOfFile];
		[fh writeData:self.getFileRequestData];
		[fh closeFile];
			
		[getFileRequestData setLength:0];
	}
	
	dataGot += [data length];
	progress = (float) dataGot / dataTotal;
	
	[installInstance updateProgress:[NSNumber numberWithFloat:progress] nextStage:NO];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [getFileRequestData release];
	commonData* sharedData = [commonData sharedData];
	
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	getFileWorking = NO;
	sharedData.updateFail = 1;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(getFileWorking == YES)
	{
		//Write leftover data to file		
		NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:self.getFilePath];
		[fh seekToEndOfFile];
		[fh writeData:self.getFileRequestData];
		[fh closeFile];
		
		[getFileRequestData release];
		
		getFileWorking = NO;
	}	
}

- (void)dealloc 
{
    [getFileConnection release];
	[getFileURL release];
	[super dealloc];
}

@end
