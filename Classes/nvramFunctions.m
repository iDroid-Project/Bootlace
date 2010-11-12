//
//  nvramFunctions.m
//  Bootlace
//
//  Created by Neonkoala on 15/05/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "nvramFunctions.h"


@implementation nvramFunctions

- (int)dumpNVRAM {
	commonData* sharedData = [commonData sharedData];
	
	kern_return_t   kr;
	io_iterator_t   io_objects;
	io_service_t    io_service;
	
	//CFMutableDictionaryRef child_props;
	CFMutableDictionaryRef service_properties;
	
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"), &io_objects);
	
	if(kr != KERN_SUCCESS)
		return -1;
	
	while((io_service= IOIteratorNext(io_objects)))
	{
		kr = IORegistryEntryCreateCFProperties(io_service, &service_properties, kCFAllocatorDefault, kNilOptions);
		if(kr == KERN_SUCCESS)
		{
			NSDictionary *nvramDict = (NSDictionary *)service_properties;
			
			if (![nvramDict objectForKey:@"platform-uuid"]) {
				NSLog(@"Failed to get UUID.");
				return -2;
			}
			if (![nvramDict objectForKey:@"opib-menu-timeout"] || ![nvramDict objectForKey:@"opib-default-os"] || ![nvramDict objectForKey:@"opib-temp-os"]) {
				return -3;
			}
			
			NSData *rawTimeout = [nvramDict objectForKey:@"opib-menu-timeout"];
			sharedData.opibTimeout = [NSString stringWithCString:[rawTimeout bytes] encoding:NSUTF8StringEncoding];
			NSData *rawDefaultOS = [nvramDict objectForKey:@"opib-default-os"];
			sharedData.opibDefaultOS = [NSString stringWithCString:[rawDefaultOS bytes] encoding:NSUTF8StringEncoding];
			NSData *rawTempOS = [nvramDict objectForKey:@"opib-temp-os"];
			sharedData.opibTempOS = [NSString stringWithCString:[rawTempOS bytes] encoding:NSUTF8StringEncoding];
			
			CFRelease(service_properties);
		}
		
		IOObjectRelease(io_service);
	}
	
	IOObjectRelease(io_objects);
	
	return 0;
}

- (int)updateNVRAM:(int)mode {
	commonData* sharedData = [commonData sharedData];
	
	kern_return_t   kr;
	io_iterator_t   io_objects;
	io_service_t    io_service;
	
	//CFMutableDictionaryRef child_props;
	CFMutableDictionaryRef service_properties;
	
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"), &io_objects);
	
	if(kr != KERN_SUCCESS)
		return -1;
	
	while((io_service= IOIteratorNext(io_objects)))
	{
		kr = IORegistryEntryCreateCFProperties(io_service, &service_properties, kCFAllocatorDefault, kNilOptions);
		if(kr == KERN_SUCCESS)
		{
			NSMutableDictionary *nvramDict = (NSMutableDictionary *)service_properties;
			
			if(mode==0) {
				//iPhoDroid fix
				NSString *hideMenuVal = @"false";
				NSData *rawHideMenu = [hideMenuVal dataUsingEncoding:NSUTF8StringEncoding];
				[nvramDict setObject:rawHideMenu forKey:@"opib-hide-menu"];
				
				NSData *rawTimeout = [sharedData.opibTimeout dataUsingEncoding:NSUTF8StringEncoding];				//Convert utf8 into raw binary
				NSData *rawDefaultOS = [sharedData.opibDefaultOS dataUsingEncoding:NSUTF8StringEncoding];
				NSData *rawTempOS = [sharedData.opibTempOS dataUsingEncoding:NSUTF8StringEncoding];
				if (rawTimeout!=nil && rawDefaultOS!=nil && rawTempOS!=nil) {										//Check for data
					[nvramDict setObject:rawTimeout forKey:@"opib-menu-timeout"];
					[nvramDict setObject:rawDefaultOS forKey:@"opib-default-os"];
					[nvramDict setObject:rawTempOS forKey:@"opib-temp-os"];
				} else {
					return -2;
				}
			} else {
				NSData *rawTempOS = [sharedData.opibTempOS dataUsingEncoding:NSUTF8StringEncoding];
				if (rawTempOS!=nil) {																				//Check for data
					[nvramDict setObject:rawTempOS forKey:@"opib-temp-os"];
				} else {
					return -2;
				}
			}
			
			IORegistryEntrySetCFProperties(io_service, service_properties);
			
			CFRelease(service_properties);
		}
		
		IOObjectRelease(io_service);
	}
	
	IOObjectRelease(io_objects);
	
	return 0;
}

- (int)backupNVRAM {
	commonData* sharedData = [commonData sharedData];
	
	kern_return_t   kr;
	io_iterator_t   io_objects;
	io_service_t    io_service;
	
	//CFMutableDictionaryRef child_props;
	CFMutableDictionaryRef service_properties;
	
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"), &io_objects);
	
	if(kr != KERN_SUCCESS)
		return -1;
	
	while((io_service= IOIteratorNext(io_objects)))
	{
		kr = IORegistryEntryCreateCFProperties(io_service, &service_properties, kCFAllocatorDefault, kNilOptions);
		if(kr == KERN_SUCCESS)
		{
			NSDictionary *nvramDict = (NSDictionary *)service_properties;
			
			if([[NSFileManager defaultManager] fileExistsAtPath:sharedData.opibBackupPath]) {
				if (![[NSFileManager defaultManager] removeItemAtPath:sharedData.opibBackupPath error:nil]) {
					return -2;
				}
			}
			
			if(![nvramDict writeToFile:sharedData.opibBackupPath atomically:YES]) {
				return -3;
			}
			
			CFRelease(service_properties);
		}
		
		IOObjectRelease(io_service);
	}
	
	IOObjectRelease(io_objects);
	
	return 0;
}

- (int)restoreNVRAM {
	commonData* sharedData = [commonData sharedData];
	
	kern_return_t   kr;
	io_iterator_t   io_objects;
	io_service_t    io_service;
	
	//CFMutableDictionaryRef child_props;
	CFMutableDictionaryRef service_properties;
	
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"), &io_objects);
	
	if(kr != KERN_SUCCESS)
		return -1;
	
	while((io_service= IOIteratorNext(io_objects)))
	{
		kr = IORegistryEntryCreateCFProperties(io_service, &service_properties, kCFAllocatorDefault, kNilOptions);
		if(kr == KERN_SUCCESS)
		{
			NSMutableDictionary *nvramDict = (NSMutableDictionary *)service_properties;
			NSDictionary *backupDict = [NSDictionary dictionaryWithContentsOfFile:sharedData.opibBackupPath];
			
			if(backupDict != nil) {
				[nvramDict setDictionary:backupDict];
			} else {
				return -2;
			}
			
			IORegistryEntrySetCFProperties(io_service, service_properties);
			
			CFRelease(service_properties);
		}
		
		IOObjectRelease(io_service);
	}
	
	IOObjectRelease(io_objects);
	
	return 0;	
}


@end
