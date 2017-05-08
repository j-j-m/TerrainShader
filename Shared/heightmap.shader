


uniform int bodyType;

#pragma transparent
#pragma body


vec4 orig = _surface.diffuse;
vec4 transformed_position = u_inverseModelTransform * u_inverseViewTransform * vec4(_surface.position, 1.0);
vec4 pos = transformed_position;

float mag = pos.z;

vec4 lowcolor = vec4(0.3,0.0,0.3,1.0);


if(mag<0.1){
_surface.diffuse = vec4(0.8,0.5,0.0,1.0);
}
else if(mag<360){
_surface.diffuse = vec4((mag)/800,0.3,0.0,1.0);


}
else{
_surface.diffuse = vec4((mag)/500,(mag)/500,(mag)/500,1.0);
}
