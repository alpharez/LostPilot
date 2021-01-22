//
//  ViewController.m
//  LostPilot
//
//  Created by Steve Clement on 2/4/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

@import CoreMotion;
#import "ViewController.h"
#import "PlayerShip.h"
#import "SpaceObject.h"
#import "WallObject.h"
#import "ExplosionEmitter.h"
#import "EnemyShip.h"
#import "saucer.h"
#import "spacefigher2.h"
#import "object.h"
#import "wall1.h"
#import "Projectile.h"
#import <OpenAl/al.h>
#import <OpenAl/alc.h>
#include <AudioToolbox/AudioToolbox.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface ViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexSaucerArray;
    GLuint _vertexSaucerBuffer;
    GLuint _vertexShipArray;
    GLuint _vertexShipBuffer;
    GLuint _vertexCubeArray;
    GLuint _vertexCubeBuffer;
    GLuint _vertexWallArray;
    GLuint _vertexWallBuffer;
    
    ALCdevice *openALDevice;
    ALCcontext *openALContext;
    ALuint outputLaserSource;
    ALuint outputLaserBuffer;
    
    CMMotionManager *_motionManager;
    
    float _score;
    BOOL _gameOver;
    
    // These are things that could be coming at the player in the game
    BOOL _fallingCubes; // might lose this one
    BOOL _asteroidField;
    BOOL _shootingUFOs;
    BOOL _wallMaze;
    BOOL _homeBase;
    int _level;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) NSMutableArray *cubes;
@property (strong, nonatomic) NSMutableArray *missiles;
@property (strong, nonatomic) NSMutableArray *walls;
@property (strong, nonatomic) PlayerShip *ship;
@property (strong, nonatomic) NSMutableArray *enemyShips;
@property (strong, nonatomic) NSMutableArray *explosions;
@property (assign) float timeSinceLastCubeSpawn;
@property (assign) float timeSinceLastUFOSpawn;
@property (assign) float timeSinceLastWallSpawn;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    [self setupAL];
    
    _motionManager = [[CMMotionManager alloc] init];
    [self startMonitoringAcceleration];
    
    self.cubes = [[NSMutableArray alloc] init];
    self.missiles = [[NSMutableArray alloc] init];
    self.enemyShips = [[NSMutableArray alloc] init];
    self.explosions = [[NSMutableArray alloc] init];
    self.walls = [[NSMutableArray alloc] init];
    self.ship = [[PlayerShip alloc] initWithPosition:GLKVector3Make(0.0, -25.0, -50.0)
                                             program:_program
                                              buffer:_vertexShipBuffer
                                               array:_vertexShipArray];
    _score = 0.0;
    _gameOver = YES;
    // game modes... each one is active at a time, make a method to pick one randomly.
    _shootingUFOs = NO;
    _asteroidField = NO;
    _wallMaze = NO;
    [self switchModes];
    
    self.ScoreLabel.text = [NSString stringWithFormat:@"%f", _score];
    self.GameOverLabel.text = @"Tap Screen to Begin";
}

- (void)dealloc
{    
    [self tearDownGL];
    [self tearDownAL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    [self loadModels];
    
    glBindVertexArrayOES(0);
}

-(void)loadModels {
    //------Saucer (Enemy Ship)
    glGenVertexArraysOES(1, &_vertexSaucerArray);
    glBindVertexArrayOES(_vertexSaucerArray);
    
    glGenBuffers(1, &_vertexSaucerBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexSaucerBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gSaucerVertexData), gSaucerVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    //------Player Ship
    glGenVertexArraysOES(1, &_vertexShipArray);
    glBindVertexArrayOES(_vertexShipArray);
    
    glGenBuffers(1, &_vertexSaucerBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexSaucerBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gSpaceFighterVertexData), gSpaceFighterVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    //------Cube (Projectile, Explosion)
    glGenVertexArraysOES(1, &_vertexCubeArray);
    glBindVertexArrayOES(_vertexCubeArray);
    
    glGenBuffers(1, &_vertexCubeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexCubeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gSpaceObjectVertexData), gSpaceObjectVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    //------Wall
    glGenVertexArraysOES(1, &_vertexWallArray);
    glBindVertexArrayOES(_vertexWallArray);
    
    glGenBuffers(1, &_vertexWallBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexWallBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gWallVertexData), gWallVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    [self stopMonitoringAcceleration];
    
    glDeleteBuffers(1, &_vertexSaucerBuffer);
    glDeleteVertexArraysOES(1, &_vertexSaucerArray);
    glDeleteBuffers(1, &_vertexShipBuffer);
    glDeleteVertexArraysOES(1, &_vertexShipArray);
    glDeleteBuffers(1, &_vertexCubeBuffer);
    glDeleteVertexArraysOES(1, &_vertexCubeArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

-(void)setupAL {
    openALDevice = alcOpenDevice(NULL);
    openALContext = alcCreateContext(openALDevice, NULL);
    alcMakeContextCurrent(openALContext);
    alGenSources(1, &outputLaserSource);
    alGenBuffers(1, &outputLaserBuffer);
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"LaserShoot44" ofType:@"caf"];
    NSURL* fileUrl = [NSURL fileURLWithPath:filePath];
    AudioFileID afid;
    OSStatus openResult = AudioFileOpenURL((__bridge CFURLRef)fileUrl, kAudioFileReadPermission, 0, &afid);
    
    if (0 != openResult) {
        NSLog(@"An error occurred when attempting to open the audio file %@: %d", filePath, (int)openResult);
        return;
    }
    UInt64 fileSizeInBytes = 0;
    UInt32 propSize = sizeof(fileSizeInBytes);
    
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propSize, &fileSizeInBytes);
    
    if (0 != getSizeResult) {
        NSLog(@"An error occurred when attempting to determine the size of audio file %@: %d", filePath, (int)getSizeResult);
    }
    UInt32 bytesRead = (UInt32)fileSizeInBytes;
    void* audioData = malloc(bytesRead);
    
    OSStatus readBytesResult = AudioFileReadBytes(afid, false, 0, &bytesRead, audioData);
    
    if (0 != readBytesResult) {
        NSLog(@"An error occurred when attempting to read data from audio file %@: %d", filePath, (int)readBytesResult);
    }
    AudioFileClose(afid);
    alBufferData(outputLaserBuffer, AL_FORMAT_STEREO16, audioData, bytesRead, 44100);
    if (audioData) {
        free(audioData);
        audioData = NULL;
    }
    alSourcei(outputLaserSource, AL_BUFFER, outputLaserBuffer);
}

-(void)tearDownAL {
    alDeleteSources(1, &outputLaserSource);
    alDeleteBuffers(1, &outputLaserBuffer);
    alcDestroyContext(openALContext);
    alcCloseDevice(openALDevice);
}

- (void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
    }
}

- (void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
    }
}

- (void)updatePositionFromMotionManager
{
    CMAccelerometerData* data = _motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.0) {
        // tilt the sprite
        [self.ship tilt:data.acceleration.x];
        // move the sprite
        if( (self.ship.position.x < -20.0) && (data.acceleration.x < 0.0)) {
            // do nothing
        } else if((self.ship.position.x > 20.0) && (data.acceleration.x > 0.0)) {
            // do nothing
        } else {
            [self.ship move:GLKVector3Make(data.acceleration.x * 2, 0.0, 0.0)];
        }
    }
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)addProjectile:(GLfloat)speed position:(GLKVector3)position {
    Projectile *p = [[Projectile alloc] initWithPosition:position
                                                 program:_program
                                                  buffer:_vertexCubeBuffer
                                                   array:_vertexCubeArray
                                                   speed:speed];
    [self.missiles addObject:p];
}

-(void)addUFO {
    float randX = [self randomValueBetween:-20.0 andValue:20.0];
    EnemyShip *ufo = [[EnemyShip alloc] initWithPosition:GLKVector3Make(randX, 30.0, -50.0)
                                                 program:_program
                                                  buffer:_vertexSaucerBuffer
                                                   array:_vertexSaucerArray];
    [self.enemyShips addObject:ufo];
}

-(void)addWall {
    float randX = [self randomValueBetween:-45.0 andValue:0.0];
    WallObject *wall1 = [[WallObject alloc] initWithPosition:GLKVector3Make(randX-10, 30.0, -50.0)
                                                    program:_program
                                                     buffer:_vertexWallBuffer
                                                    array:_vertexWallArray];
    /*
    WallObject *wall2 = [[WallObject alloc] initWithPosition:GLKVector3Make(randX+26.0, 30.0, -50.0)
                                                     program:_program
                                                      buffer:_vertexWallBuffer
                                                       array:_vertexWallArray];
     */
    [self.walls addObject:wall1];
    //[self.walls addObject:wall2];
}

-(void)gameOver {
    _gameOver = YES;
    self.GameOverLabel.text = @"Game Over";
    self.GameOverLabel.hidden = NO;
}

-(void)restartGame {
    _gameOver = NO;
    _score = 0.0;
    self.GameOverLabel.hidden = YES;
    [self.walls removeAllObjects];
    [self.enemyShips removeAllObjects];
}

-(void)switchModes{
    int n = arc4random()%3;
    switch(n) {
        case 0:
            _wallMaze = NO;
            _shootingUFOs = YES;
            break;
        case 1:
            _wallMaze = NO;
            _shootingUFOs = YES;
            break;
        default:
            _wallMaze = NO;
            _shootingUFOs = YES;
            break;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    if(!_gameOver) {
        //NSMutableArray *cubesToDelete = [[NSMutableArray alloc] init];  // array for cubes that went by
        NSMutableArray *missilesToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *UFOsToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *WallsToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *explosionsToDelete = [[NSMutableArray alloc] init];
    
        [self updatePositionFromMotionManager];
        
        // move objects
        for(Projectile *p in self.missiles) {
            [p move];
            if((p.position.y > 30.0) || (p.position.y < -25.0)) {
                [missilesToDelete addObject:p];
            }
        }
        for(EnemyShip *ufo in self.enemyShips) {
            [ufo move];
            if([self randomValueBetween:1.0 andValue:10.0] > 9.0) {
                //[self addCube:ufo.position];
            }
            if(ufo.position.y < -35.0) {
                [UFOsToDelete addObject:ufo];
            }
        }
        for(WallObject *wall in self.walls) {
            [wall move];
            if(wall.position.y < -35.0) {
                [WallsToDelete addObject:wall];
            }
        }
        for(ExplosionEmitter *explosion in self.explosions) {
            [explosion move];
            if(explosion.finished) {
                [explosionsToDelete addObject:explosion];
            }
        }
        
        // check for collisions
        if(_shootingUFOs) {
            for(EnemyShip *ufo in self.enemyShips) {
                for(Projectile *p in self.missiles) {
                    if(CGRectIntersectsRect([ufo boundingBox], [p boundingBox])) {
                        [missilesToDelete addObject:p];
                        [UFOsToDelete addObject:ufo];
                        ExplosionEmitter *explosion = [[ExplosionEmitter alloc] initWithPosition:ufo.position
                                                                                         program:_program
                                                                                          buffer:_vertexCubeBuffer
                                                                                           array:_vertexCubeArray];
                        [self.explosions addObject:explosion];
                    }
                }
                if(CGRectIntersectsRect([self.ship boundingBox], [ufo boundingBox])) {
                    [self gameOver];
                }
            }
        }
        if(_wallMaze) {
            for(WallObject *wall in self.walls) {
                for(Projectile *p in self.missiles) {
                    if(CGRectIntersectsRect([wall boundingBox], [p boundingBox])) {
                        [missilesToDelete addObject:p];
                    }
                }
                if(CGRectIntersectsRect([self.ship boundingBox], [wall boundingBox])) {
                    [self gameOver];
                }
            }
        }
        
        // spawn stuff
        if(_shootingUFOs) {
            self.timeSinceLastUFOSpawn += self.timeSinceLastUpdate;
            if(self.timeSinceLastUFOSpawn > 1.0) {
                self.timeSinceLastUFOSpawn = 0;
                [self addUFO];
            }
        }
        if(_wallMaze) {
            self.timeSinceLastWallSpawn += self.timeSinceLastUpdate;
            if(self.timeSinceLastWallSpawn > 1.3) {
                self.timeSinceLastWallSpawn = 0;
                [self addWall];
            }
        }
        
        // delete objects
        for(Projectile *p in missilesToDelete) {
            [self.missiles removeObject:p];
        }
        for(EnemyShip *ufo in UFOsToDelete) {
            [self.enemyShips removeObject:ufo];
        }
        for(WallObject *wall in WallsToDelete) {
            [self.walls removeObject:wall];
        }
        for(ExplosionEmitter *explosion in explosionsToDelete) {
            [self.explosions removeObject:explosion];
        }
        
        // update score
        _score += 0.0017;
        self.ScoreLabel.text = [NSString stringWithFormat:@"%f", _score];
        
        if(_score > 1.0) {
            [self switchModes];
        }
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    //====== Clear Screen
    glClearColor(0.2f, 0.2f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //====== Render Ship
    [self.ship renderWithProjection:projectionMatrix];
    //====== Render UFOs
    if([self.enemyShips count] != 0) {
        for(EnemyShip *ufo in self.enemyShips) {
            [ufo renderWithProjection:projectionMatrix];
        }
    }
    //====== render walls
    if([self.walls count] != 0) {
        for(WallObject *wall in self.walls) {
            [wall renderWithProjection:projectionMatrix];
        }
    }
    //====== render missiles
    if([self.missiles count] != 0)
    {
        for(Projectile *p in self.missiles) {
            [p renderWithProjection:projectionMatrix];
        }
    }
    //====== render explosions
    if([self.explosions count] != 0) {
        for(ExplosionEmitter *explosion in self.explosions) {
            [explosion renderWithProjection:projectionMatrix];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_gameOver) {
        // start game
        [self restartGame];
    } else {
        [self addProjectile:2.0 position:self.ship.position];
        if(!_gameOver) {
            alSourcePlay(outputLaserSource);    // pew pew
        }
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
