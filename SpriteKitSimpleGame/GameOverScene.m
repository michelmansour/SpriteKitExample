//
//  GameOverScene.m
//  SpriteKitSimpleGame
//
//  Created by Michel Mansour on 1/22/14.
//  Copyright (c) 2014 Michel Mansour. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"

@implementation GameOverScene

- (id)initWithSize:(CGSize)size won:(BOOL)won {
    self = [super initWithSize:size];
    
    if (self) {
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        NSString *message;
        if (won) {
            message = @"You Won!";
        } else {
            message = @"You Lose :[";
        }
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        label.text = message;
        label.fontSize = 40;
        label.fontColor = [SKColor blackColor];
        label.position = CGPointMake(self.size.width / 2, self.size.height / 2);
        [self addChild:label];
        
        [self runAction:
            [SKAction sequence:@[
                [SKAction waitForDuration:3.0],
                [SKAction runBlock:^{
                    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
                    SKScene *myScene = [[MyScene alloc] initWithSize:self.size];
	                [self.view presentScene:myScene transition:reveal];
                }]
            ]]
         ];
    }
    
    return self;
}

@end
