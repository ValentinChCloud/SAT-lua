# SAT-lua
Separating Axis theorem in lua.

It's a simple Lua library for performing collision detection of simple 2D shapes. It uses the [Separating Axis Theorem](http://en.wikipedia.org/wiki/Hyperplane_separation_theorem)

The aim is to keep it simple as possible, so you don't change the structure of your code and how you store values.


Also it's a first try, contributions are welcome.

It supports detecting collisions between:
<ul>
<li> - Circles - Circles </li>
<li> - Circles - Convex polygons </li>
<li>- Convex polygons - Convex polygons </li>
</ul>
 
If a circle is involved in the collision, it returns the point of collision on the circle.

It's released under the MIT license.



# How to use 

<strong> Get the repo, keep SAT.lua and erase files </strong>

```
function love.load()
SAT  = require("SAT")


end


function love.update()

	-- collider, must be a table with
	-- collider.type = "circle" or "polygon"
	-- collider.vertices -- if it's a polygon
	-- collider.radius -- if it's a circle
	
	-- body must be a table as  like {400,400}
	local shape_a = SAT.new_shape(collider_a, body_a)
	local shape_b = SAT.new_shape(collider_b, body_b)
	
	
	local collide, mtv_axis, overlap = SAT.is_colliding(shape_a, shape_b)
	
	if collide then
	-- shape_a is colliding with b. To stop the colliding, move the shape_a along the mtx_axis.
		local mtv = { mtv_axis[1] * overlap, mtv_axis[2] * overlap]}
		shape_a.position = shape_a.position + mtv -- use a function to add two vectors.
	
	end
end

``` 


# Update futur 
Get the point of collision and faces involded in polygon - polygon collision.
I have already something but the code is too dirty and some issues have to fix.