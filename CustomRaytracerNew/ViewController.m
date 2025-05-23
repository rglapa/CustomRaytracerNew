//
//  ViewController.m
//  CustomRaytracerNew
//
//  Created by Ruben Glapa on 3/29/25.
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import "../Renderer/AAPLRenderer.h"

@implementation ViewController
{
    MTKView *_view;
    
    AAPLRenderer *_renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _configureBackdrop:_configBackdrop];
    
    [_loadingSpinner startAnimation:self];
    
    _view = (MTKView *)self.view;
    _view.layer.backgroundColor = [NSColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:1.-0].CGColor;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.preferredFramesPerSecond = 30;
    
    NSAssert(_view.device, @"Metal is not supported on this device");
    
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    
    CGSize size = _view.bounds.size;
    __weak ViewController* weakSelf = self;
    dispatch_async(q, ^(){
        ViewController* strongSelf;
        if ((strongSelf = weakSelf))
        {
            strongSelf->_renderer = [[AAPLRenderer alloc] initWithMetalKitView:strongSelf->_view size:size];
            
            NSAssert(strongSelf->_renderer, @"Renderer failed initialization");
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                ViewController* innerStrongSelf;
                if ((innerStrongSelf = weakSelf))
                {
                    [innerStrongSelf->_loadingSpinner stopAnimation:innerStrongSelf];
                    innerStrongSelf->_loadingLabel.hidden = YES;
                    
                    [innerStrongSelf->_renderer mtkView:innerStrongSelf->_view
                                 drawableSizeWillChange:innerStrongSelf->_view.drawableSize];
                    
                    innerStrongSelf->_view.delegate = innerStrongSelf->_renderer;
                }
            });
        }
    });
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)onRenderModeSegmentedControlAction:(id)sender
{
    if (sender == _renderModeControl)
    {
        _renderer.renderMode = (RenderMode)_renderModeControl.indexOfSelectedItem;
    }
}

- (IBAction)onSpeedSliderAction:(id)sender
{
    if (sender == _speedSlider)
    {
        float newValue = _speedSlider.floatValue;
        [_renderer setCameraPanSpeedFactor:newValue];
    }
}

- (IBAction)onMetallicBiasAction:(id)sender
{
    if (sender == _metallicBiasSlider)
    {
        [_renderer setMetallicBias:_metallicBiasSlider.floatValue];
    }
}

- (IBAction)onRoughnessBiasAction:(id)sender
{
    if (sender == _roughnessBiasSlider)
    {
        [_renderer setRoughnessBias:_roughnessBiasSlider.floatValue];
    }
}

- (IBAction)onExposureSliderAction:(id)sender
{
    if (sender == _exposureSlider)
    {
        [_renderer setExposure:_exposureSlider.floatValue];
    }
}

- (void)_configureBackdrop:(NSView *)view
{
    view.wantsLayer = YES;
    view.layer.borderWidth = 1.0f;
    view.layer.cornerRadius = 8.0f;
}

@end
