//
//  Texture.metal
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

#include <metal_stdlib>
using namespace metal;

struct TextureData {
    float4 vertices[[ position ]];
    float2 texCoords;
};

vertex TextureData draw_texture_vertex(uint vid[[vertex_id]],
                                       constant float2 *position [[ buffer(0) ]],
                                       constant float2 *texCoords [[ buffer(1) ]]) {
    TextureData data;
    data.vertices = float4(position[vid], 0, 1);
    data.texCoords = texCoords[vid];
    return data;
}
fragment float4 draw_texture_fragment(TextureData data [[ stage_in ]],
                                      texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    float4 color = texture.sample(defaultSampler, data.texCoords);
    float a = color[3];
    float b = color[2];
    float g = color[1];
    float r = color[0];
    return float4(r, g, b, a);
}

kernel void add_color_to_texture(uint2 gid [[ thread_position_in_grid ]],
                                 constant float4 &color [[ buffer(0) ]],
                                 texture2d<float, access::write> resultTexture [[ texture(0) ]]) {
    resultTexture.write(color, gid);
}
