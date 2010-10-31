//
//  BSPatch.m
//  BootlaceV2
//
//  Created by Neonkoala on 30/09/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import "BSPatch.h"


@implementation BSPatch

- (off_t)offtin:(u_char *)buf {
	off_t y;
	
	y=buf[7]&0x7F;
	y=y*256;y+=buf[6];
	y=y*256;y+=buf[5];
	y=y*256;y+=buf[4];
	y=y*256;y+=buf[3];
	y=y*256;y+=buf[2];
	y=y*256;y+=buf[1];
	y=y*256;y+=buf[0];
	
	if(buf[7]&0x80) y=-y;
	
	return y;
}

- (int)bsPatch:(NSString *)filePath withPatch:(NSString *)patchPath {
	NSString *patchedFilePath = [filePath stringByAppendingPathExtension:@"patched"];
	
	FILE *f, *cpf, *dpf, *epf;
	BZFILE *cpfbz2, *dpfbz2, *epfbz2;
	int cbz2err, dbz2err, ebz2err;
	int fd;
	ssize_t oldsize,newsize;
	ssize_t bzctrllen,bzdatalen;
	u_char header[32],buf[8];
	u_char *old, *new;
	off_t oldpos,newpos;
	off_t ctrl[3];
	off_t lenread;
	off_t i;
	
	/* Open patch file */
	if ((f = fopen([patchPath cStringUsingEncoding:NSUTF8StringEncoding], "r")) == NULL) {
		DLog(@"Could not open patch");
	}
	
	/*
	 File format:
	 0	8	"BSDIFF40"
	 8	8	X
	 16	8	Y
	 24	8	sizeof(newfile)
	 32	X	bzip2(control block)
	 32+X	Y	bzip2(diff block)
	 32+X+Y	???	bzip2(extra block)
	 with control block a set of triples (x,y,z) meaning "add x bytes
	 from oldfile to x bytes from the diff block; copy y bytes from the
	 extra block; seek forwards in oldfile by z bytes".
	 */
	
	/* Read header */
	if (fread(header, 1, 32, f) < 32) {
		DLog(@"Corrupt patch. Header invalid");
	}
	
	/* Check for appropriate magic */
	if (memcmp(header, "BSDIFF40", 8) != 0) {
		DLog(@"Corrupt patch. Magic wrong.");
	}
	
	/* Read lengths from header */
	bzctrllen = [self offtin:(header+8)];
	bzdatalen = [self offtin:(header+16)];
	newsize = [self offtin:(header+24)];
	if((bzctrllen<0) || (bzdatalen<0) || (newsize<0)) {
		DLog(@"Corrupt patch");
	}
	
	/* Close patch file and re-open it via libbzip2 at the right places */
	if ((cpf = fopen([patchPath cStringUsingEncoding:NSUTF8StringEncoding], "r")) == NULL)
		DLog(@"fopen(%s)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding]);
	if (fseeko(cpf, 32, SEEK_SET))
		DLog(@"fseeko(%s, %lld)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding], (long long)32);
	if ((cpfbz2 = BZ2_bzReadOpen(&cbz2err, cpf, 0, 0, NULL, 0)) == NULL)
		DLog(@"BZ2_bzReadOpen, bz2err = %d", cbz2err);
	if ((dpf = fopen([patchPath cStringUsingEncoding:NSUTF8StringEncoding], "r")) == NULL)
		DLog(@"fopen(%s)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding]);
	if (fseeko(dpf, 32 + bzctrllen, SEEK_SET))
		DLog(@"fseeko(%s, %lld)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding], (long long)(32 + bzctrllen));
	if ((dpfbz2 = BZ2_bzReadOpen(&dbz2err, dpf, 0, 0, NULL, 0)) == NULL)
		DLog(@"BZ2_bzReadOpen, bz2err = %d", dbz2err);
	if ((epf = fopen([patchPath cStringUsingEncoding:NSUTF8StringEncoding], "r")) == NULL)
		DLog(@"fopen(%s)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding]);
	if (fseeko(epf, 32 + bzctrllen + bzdatalen, SEEK_SET))
		DLog(@"fseeko(%s, %lld)", [patchPath cStringUsingEncoding:NSUTF8StringEncoding], (long long)(32 + bzctrllen + bzdatalen));
	if ((epfbz2 = BZ2_bzReadOpen(&ebz2err, epf, 0, 0, NULL, 0)) == NULL)
		DLog(@"BZ2_bzReadOpen, bz2err = %d", ebz2err);
	
	if(((fd=open([filePath cStringUsingEncoding:NSUTF8StringEncoding],O_RDONLY,0))<0) ||
	   ((oldsize=lseek(fd,0,SEEK_END))==-1) ||
	   ((old=malloc(oldsize+1))==NULL) ||
	   (lseek(fd,0,SEEK_SET)!=0) ||
	   (read(fd,old,oldsize)!=oldsize) ||
	   (close(fd)==-1)) DLog(@"%s", [filePath cStringUsingEncoding:NSUTF8StringEncoding]);
	new = malloc(newsize+1);
	
	oldpos=0;newpos=0;
	while(newpos<newsize) {
		/* Read control data */
		for(i=0;i<=2;i++) {
			lenread = BZ2_bzRead(&cbz2err, cpfbz2, buf, 8);
			if ((lenread < 8) || ((cbz2err != BZ_OK) &&
								  (cbz2err != BZ_STREAM_END)))
				DLog(@"Corrupt patch\n");
			ctrl[i] = [self offtin:buf];
		};
		
		/* Sanity-check */
		if(newpos+ctrl[0]>newsize)
			DLog(@"Corrupt patch\n");
		
		/* Read diff string */
		lenread = BZ2_bzRead(&dbz2err, dpfbz2, new + newpos, ctrl[0]);
		if ((lenread < ctrl[0]) ||
		    ((dbz2err != BZ_OK) && (dbz2err != BZ_STREAM_END)))
			DLog(@"Corrupt patch\n");
		
		/* Add old data to diff string */
		for(i=0;i<ctrl[0];i++)
			if((oldpos+i>=0) && (oldpos+i<oldsize))
				new[newpos+i]+=old[oldpos+i];
		
		/* Adjust pointers */
		newpos+=ctrl[0];
		oldpos+=ctrl[0];
		
		/* Sanity-check */
		if(newpos+ctrl[1]>newsize)
			DLog(@"Corrupt patch\n");
		
		/* Read extra string */
		lenread = BZ2_bzRead(&ebz2err, epfbz2, new + newpos, ctrl[1]);
		if ((lenread < ctrl[1]) ||
		    ((ebz2err != BZ_OK) && (ebz2err != BZ_STREAM_END)))
			DLog(@"Corrupt patch\n");
		
		/* Adjust pointers */
		newpos+=ctrl[1];
		oldpos+=ctrl[2];
	};
	
	/* Clean up the bzip2 reads */
	BZ2_bzReadClose(&cbz2err, cpfbz2);
	BZ2_bzReadClose(&dbz2err, dpfbz2);
	BZ2_bzReadClose(&ebz2err, epfbz2);
	fclose(cpf);
	fclose(dpf);
	fclose(epf);
	
	/* Write the new file */
	if(((fd=open([patchedFilePath cStringUsingEncoding:NSUTF8StringEncoding],O_CREAT|O_TRUNC|O_WRONLY,0666))<0) || (write(fd,new,newsize)!=newsize) || (close(fd)==-1)) {
		DLog(@"Could not write to file");
	}
	
	free(new);
	free(old);
	
	return 0;
	
	
}

@end
