float dotProduct = max(-0.4, dot(_surface.normal,_light.direction));

_lightingContribution.diffuse += (dotProduct * _light.intensity.rgb);
_lightingContribution.diffuse = floor(_lightingContribution.diffuse * 50.0) / 49.0;

vec3 halfVector = normalize(_light.direction + _surface.view);


_lightingContribution.specular += (dotProduct * _light.intensity.rgb);
