# Notes
- for `RefractiveBRDF` we need to differentiate inside from outside bacuase of the ddiferent beahaviour of rays considering the refractive index.
- i think it's tought cause BRDF is proper of a Material that is proper of a Shape so the BRDF can't have a priori the information weather the intersection is inside or outside the Shape
- the refractance index information can be given to the ray. The BRDF would need to have the whole ray as argument and not only the ray.dir