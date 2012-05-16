//
//  MyScheduler.m
//  ChordPlayer
//
//  Created by 吉岡 紘二 on 12/05/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MyScheduler.h"

@implementation MyScheduler

static MyScheduler *sharedMyScheduler = nil;

//This class is Singleton
+(id)sharedMyScheduler{
	if (sharedMyScheduler == nil){
		sharedMyScheduler = [[self alloc] init];
	}
	return sharedMyScheduler;
}

-(void)setSoundDelegate : (SoundDelegate *)soundDelegate{
	soundDelegate_ = soundDelegate;
}

/*
-(void)play:(float)freq withWhile:(int)msec{
	NSLog(@"MyScheduler played with %f[hz], %lu[msec]", freq, msec);
	Synth *synth = [soundDelegate_ synth];
}
*/
-(void)noteOn:(int)noteNumber{
	Synth *synth = [soundDelegate_ synth];
	synth->noteOn(noteNumber, 127);
}

-(void)noteOff:(int)noteNumber{
	Synth *synth = [soundDelegate_ synth];
	synth->noteOff(noteNumber);
}

@end
