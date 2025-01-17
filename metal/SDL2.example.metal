#import "SDL2/SDL.h"

@implementation Metal

- (void)renderFrame:(GLuint)glContext {
  // Clear the screen with a red color
  glClear(GL_COLOR_BUFFER_BIT);

  // Set the shader program and vertex buffer
  id<MTLShader> shader = [[MTLShader alloc] initWithType: kMTLShaderTypeColorRed];
  MTLDevice *device = [MTLDevice new];
  [device executeCommandBufferWithCommand:shader commandQueue:glContext options:nil];

  // Draw some graphics using the red color
  for (int i = 0; i < 10; ++i) {
    MTLPoint3D point = {i * 20.0, 50.0, 0.0};
    [device executeCommandBufferWithCommand:shader commandQueue:glContext options:nil atLocation:0
                                           arguments:{{0,1}, {point.x, point.y, point.z}}];

    // Fill the screen with a red rectangle
    for (int j = -10; j <= 10; ++j) {
      float y = 50.0 + j * 20.0;
      MTLVector3D position = {j * 20.0, 50.0, 0.0};
      [device executeCommandBufferWithCommand:shader commandQueue:glContext options:nil atLocation:2
                                                           arguments:{{0,1}, {position.x, position.y, position.z}}];
    }
  }

  // Swap the buffers for the next frame
  glFlush();
}

- (void)renderWindow:(SDL_Window *)window {
  MTLDevice *device = [MTLDevice new];
  [device executeCommandBufferWithCommand:[MTLShader shaderWithType:kMTLShaderTypeRender]
                                        commandQueue:glContext options:nil];

  // Clear the screen
  glClearColor(1.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  // Fill the screen with a red rectangle
  for (int i = -10; i <= 10; ++i) {
    float y = 50.0 + i * 20.0;
    MTLVector3D position = {i * 20.0, 50.0, 0.0};
    [device executeCommandBufferWithCommand:[MTLShader shaderWithType:kMTLShaderTypeRender]
                                        commandQueue:glContext options:nil atLocation:2
                                                           arguments:{{0,1}, {position.x, position.y, position.z}}];
  }

  // Swap the buffers for the next frame
  glFlush();
}

@end
