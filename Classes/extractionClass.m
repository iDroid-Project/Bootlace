//
//  extractionClass.m
//  BootlaceV2
//
//  Created by Neonkoala on 15/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "extractionClass.h"

@implementation extractionClass

@synthesize installInstance;

- (int)inflateGzip:(NSString *)sourcePath toDest:(NSString *)destPath {
	installInstance = [[installClass alloc] init];
	commonData *sharedData = [commonData sharedData];
	int dataRead = 0;
	
	NSFileHandle *destHandle = [NSFileHandle fileHandleForWritingAtPath:destPath];
	FILE *dest = fdopen([destHandle fileDescriptor], "w");
	
	//Convert source path into something a C library can handle
	const char* sourceCString = [sourcePath cStringUsingEncoding:NSASCIIStringEncoding];
	
	gzFile *source = gzopen(sourceCString, "rb");
	
	unsigned int length = 1024*256;	//Thats like 256Kb
	void *buffer = malloc(length);
	
	while (true)
	{       
		int read = gzread(source, buffer, length);
		
		dataRead += length;
		float progress = (float) dataRead/sharedData.updateSize;
		[installInstance updateProgress:[NSNumber numberWithFloat:progress] nextStage:NO];
		
		if (read > 0)
		{
			fwrite(buffer, read, 1, dest);
		}
		else if (read == 0)
			break;
		else if (read == -1)
		{
			NSLog(@"Decompression failed");
			return -1;
		}
		else
		{
			NSLog(@"Unexpected state from zlib");
			return -2;
		}
	}
	
	gzclose(source);
	free(buffer);
	[destHandle closeFile];

	return 0;
}

- (int)extractTar:(NSString *)sourcePath toDest:(NSString *)destDir {
	installInstance = [[installClass alloc] init];
	commonData *sharedData = [commonData sharedData];
	int done = 0;
		
	NSString *destPath;
	const char* sourceCString = [sourcePath cStringUsingEncoding:NSASCIIStringEncoding];
	
	struct archive *tar;
	struct archive_entry *entry;
	int result;
	
	int length = 1024*256;	//Thats like 256Kb
	void *buffer = malloc(length);
	size_t size;
	
	tar = archive_read_new();
	archive_read_support_format_tar(tar);
	result = archive_read_open_filename(tar, sourceCString, 10240);
	if (result != ARCHIVE_OK)
		return -1;
	
	while (archive_read_next_header(tar, &entry) == ARCHIVE_OK) {
		const char* cRelativePath = archive_entry_pathname(entry);
		NSString *relativePath = [NSString stringWithCString:cRelativePath encoding:NSUTF8StringEncoding];
		
		destPath = [destDir stringByAppendingPathComponent:relativePath];
		
		if(archive_entry_mode(entry)==16877) {
			[[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
		} else {
			[[NSFileManager defaultManager] createFileAtPath:destPath contents:nil attributes:nil];
			NSFileHandle *destHandle = [NSFileHandle fileHandleForWritingAtPath:destPath];
			FILE *dest = fdopen([destHandle fileDescriptor], "w");

			while (true) {
				size = archive_read_data(tar, buffer, length);
				done += size;
				float progress = (float) done/sharedData.updateSize;
				[installInstance updateProgress:[NSNumber numberWithFloat:progress] nextStage:NO];
				if (size > 0) {
					fwrite(buffer, size, 1, dest);
				} else if (size == 0) {
					break;
				} else if (size < 0) {
					NSLog(@"Extraction failed");
					return -2;
				}
			}
			fclose(dest);
		}
	}
	result = archive_read_finish(tar);
	if (result != ARCHIVE_OK) {
		return -3;
	}
	
	return 0;
}

@end
