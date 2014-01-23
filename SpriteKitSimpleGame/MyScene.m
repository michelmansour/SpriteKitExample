//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Michel Mansour on 1/22/14.
//  Copyright (c) 2014 Michel Mansour. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

static const uint32_t projectileCategory    = 0x1 << 0;
static const uint32_t monsterCategory       = 0x1 << 1;

@interface MyScene () <SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode *player;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monstersDestroyed;
@end

static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

@implementation MyScene

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        self.player.position = CGPointMake(self.player.size.width / 2, self.frame.size.height / 2);
        [self addChild:self.player];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}

- (void)addMonster {
    
    // Create sprite
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    // Monster physics and collision
    monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    monster.physicsBody.dynamic = YES;
    monster.physicsBody.categoryBitMask = monsterCategory;
    monster.physicsBody.contactTestBitMask = projectileCategory;
    monster.physicsBody.collisionBitMask = 0;
    
    // Determine where to spawn the monster along the y-axis
    int minY = monster.size.height / 2;
    int maxY = self.frame.size.height - monster.size.height / 2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // Create the monster slightly off-screen along the right edge,
    // and along a random position along the y-axis as calculated above
    monster.position = CGPointMake(self.frame.size.width + monster.size.width / 2, actualY);
    [self addChild:monster];
    
    // Determine the speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create the actions
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width / 2, actualY) duration:actualDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];

    SKAction *loseAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        [self.view presentScene:gameOverScene transition:reveal];
    }];
    [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}

- (void)update:(NSTimeInterval)currentTime {
    // Handle time delta
    // If we drop below 60fps, we still want everything to move the same distance
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // more than a second since last update
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Sound effects
    [self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];
    
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    // Set up initial location of projectile
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    projectile.position = self.player.position;
    
    // Collision detection
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width / 2];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = monsterCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    // Determine offset of location to projectile
    CGPoint offset = rwSub(location, projectile.position);
    
    // Bail out if you are shooting down or backwards
    if (offset.x <= 0) return;
    
    // OK to add now - we've double checked the position
    [self addChild:projectile];
    
    // Get the direction of the shot
    CGPoint direction = rwNormalize(offset);
    
    // Make it shoot far enough to be guranteed off screen
    CGPoint shootAmount = rwMult(direction, 1000);
    
    // Add the shoot amount to the current position
    CGPoint realDest = rwAdd(shootAmount, projectile.position);
    
    // Create the actions
    float velocity = 480.0 / 1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

- (void)projectile:(SKSpriteNode *)projectile didCollidewithMonster:(SKSpriteNode *)monster {
    NSLog(@"Hit");
    [projectile removeFromParent];
    [monster removeFromParent];
    self.monstersDestroyed++;
    if (self.monstersDestroyed > 5) {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
        (secondBody.categoryBitMask & monsterCategory) != 0) {
        [self projectile:(SKSpriteNode *)firstBody.node didCollidewithMonster:(SKSpriteNode *)secondBody.node];
    }
}

@end