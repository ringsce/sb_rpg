#import <SDL2/SDL.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@implementation MetalRenderer {
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    CAMetalLayer *metalLayer;
}

- (instancetype)initWithWindow:(SDL_Window *)window {
    self = [super init];
    if (self) {
        // Initialize Metal device and command queue
        device = MTLCreateSystemDefaultDevice();
        commandQueue = [device newCommandQueue];

        // Attach Metal layer to SDL window
        metalLayer = [CAMetalLayer layer];
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        metalLayer.framebufferOnly = YES;

        // Retrieve the Metal layer and attach to the SDL window
        SDL_MetalView metalView = SDL_Metal_CreateView(window);
        NSView *nsView = (__bridge NSView *)SDL_Metal_GetView(metalView);
        metalLayer.frame = nsView.bounds;
        [nsView setLayer:metalLayer];
        [nsView setWantsLayer:YES];
    }
    return self;
}

- (void)renderFrame {
    // Create a drawable and command buffer
    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    if (!drawable) return;

    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = drawable.texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)dealloc {
    metalLayer = nil;
    device = nil;
    commandQueue = nil;
}

@end
