//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Michel Mansour on 1/22/14.
//  Copyright (c) 2014 Michel Mansour. All rights reserved.
//

#import "MyScene.h"

@interface MyScene ()
@property (nonatomic) SKSpriteNode *player;
@end

@implementation MyScene

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        self.player.position = CGPointMake(100, 100);
        [self addChild:self.player];
    }
    return self;
}

@end