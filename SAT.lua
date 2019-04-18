--[[
MIT License

Copyright (c) 2019 Valentin Chambon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]






------------------------------------------------------------------
-- MATH functions
------------------------------------------------------------------
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end

function math.dist(point_a, point_b) return ((point_b[1]-point_a[1])^2+(point_b[2]-point_a[2])^2)^0.5 end

function math.line_overlap(a_min, a_max, b_min, b_max)

  local min1 = math.min(a_max,b_max)
  local max1 = math.max(a_min,b_min)

  local diff = min1-max1
  diff = math.floor(diff)
  return math.max(0,diff)

end

------------------------------------------------------------------
-- VECTOR functions
------------------------------------------------------------------


local vector = {}



function vector.addition(v1,v2) return {v1[1]+v2[1],v1[2]+v2[2]} end



function vector.substract(v1, v2) return {v1[1]-v2[1],v1[2]-v2[2]} end

-- Multiply a vector by a scalar
function vector.multiply(vector, scale) return {vector[1] *scale, vector[2] * scale} end

-- Dot product between two vector
function vector.dot(v1,v2) return v1[1]*v2[1] + v1[2]*v2[2] end


function vector.magnitude(v1) return math.sqrt(v1[1]*v1[1] + v1[2]*v1[2]) end

function vector.normalize(v1)  
  local unit = vector.magnitude(v1)

  return {v1[1]/unit, v1[2]/unit }
end


-- Rotate a vector according to an orgin 
function vector.rotate(vecteur, origin, angle)
  -- Take the negatives, because origin axis is in the left corner.
  local sinus = math.sin(-angle)
  local cosinus = math.cos(-angle)

  local x1 = vecteur[1] - origin[1]
  local y1 = vecteur[2] - origin[2]
  x = math.round(x1 * cosinus - y1 *sinus,2)
  y  = math.round(x1 * sinus + y1 * cosinus,2)

  local new_vector = { x + origin[1],y +origin[2]  }

  return new_vector
end











------------------------------------------------------------------
-- SAT functions
------------------------------------------------------------------
-- Separating Axis theorem, for detect collision between oriented objetcs
-- Three main functions :
--  circle_cirlce 
--  circle_poly
--  poly_poly
-- All these three functions can return the point of intersection if mode == true


local SAT = {}

-- Create a new SAT object. It needs type information  of the object.
-- @collider : table, polygon collider or circler collider, it needs to have a type field, and a radius field for circle, and vertices for
-- polygon
-- @body : table, field : position
-- return : table, new SAT object
function SAT.new_shape(collider, body)
  if collider.type == "circle" then
    return  SAT.new_circle(body.position, collider.radius)
  else
    return  SAT.new_poly(body.position, collider.vertices)
  end

end

-- Create a body for your SAT object
-- @position : table
-- @shape_type : string
-- return : table,  a new body
function SAT.new_body(position, shape_type)
  assert(type(position) == "table")
  assert(type(shape_type) == "string")
  local new_body = { position = position, type = shape_type}
  return new_body
end



-- Create a body for your SAT object
-- @position : table
-- @radius : int
-- return : table, a new SAT circle object

function SAT.new_circle(position, radius)
  local new_circle = SAT.new_body(position, "circle")
  new_circle.radius = radius

  return new_circle
end

-- Create a body for your SAT object
-- @position : table
-- @vertices : table
-- return : table, a new SAT polygon object


function SAT.new_poly(position, vertices)
  local new_poly = SAT.new_body(position, "poly")
  new_poly.vertices = vertices

  return new_poly
end

-- Found the nearest vertex to a position
-- @position : table
-- @vertices : table
-- return : table, the nearest vertex 
function SAT.found_nearest_vertex (position, vertices)
  local min = math.dist(position, vertices[1])
  local d = 0
  local index = 1
  for i=2, #vertices do
    d = math.dist(position, vertices[i])
    if d < min then
      min = d
      index = i
    end
  end
  return vertices[index]
end

-- Get all the axes from a shape. Iterating over all edge, normalize it and rotate from 90 °
-- @vertices : table
-- @faces_mod : boolean , if true, it will return the edge associated to the axis
-- return : table, of all axis found for theses vertices and the faces associated are optionnal
function SAT.get_axes(vertices, faces_mod)
  local v1 = {}
  local v2 = {}
  local normal = {}
  local axis = {}

  local axes = {}
  local faces = {}
  for i = 1, #vertices do
    v1 = vertices[i]
    v2 = vertices[i+1 == #vertices+1 and 1 or i+1]
    normal = vector.normalize(vector.substract(v2,v1))
    axis = vector.rotate(normal, {0,0}, math.pi/2)
    table.insert(axes, axis)
    table.insert(faces,{v1,v2})
  end
  if faces_mod then
    return axes, faces
  else
    return axes
  end
end


-- Found the nearest edge to another edge. In SAT, the nearest edge after found the separating axis, is the edge with the less dot product
-- over this faces.
-- @face : table,  e.g-- {{100,100},{200,200}}
-- @vertices : table
-- return : table, the nearest vertex 

function SAT.found_nearest_edge(face, vertices)
  local v1 = vertices[1]
  local v2 = vertices[2]
  local face_vector = vector.substract(face[2],face[1])

  local dot = vector.dot(vector.substract(v2, v1), face_vector)
  local min_dot = dot
  local second_face = {v2, v1}
  local index = 1
  for i = 2, #vertices do
    v1  = vertices[i]
    v2  = vertices[i+1 == #vertices+1 and 1 or i+1]
    dot = vector.dot(vector.substract(v2,v1),face_vector)
    if dot < min_dot then
      min_dot = dot
      index = i
      second_face =  {v1, v2}
    end
  end

  return second_face, index
end


-- Determine is two sat_object are colliding. It choose which function to call,  function of the shapes types.
-- @sat_object_a : table, sat_object, it's the object you want to if it's colliding with something.
-- @sat_object_b :table, sat_object, it's the other object.
-- return : boolean, mtv_axis, mtv --if there is a circle object, return the intersection point on the circle.
function SAT.is_colliding( sat_object_a, sat_object_b)
  if sat_object_a.type == "poly" then
    if sat_object_b.type == "poly" then
      return   SAT.poly_poly(sat_object_a,sat_object_b)
    else
      return SAT.circle_poly(sat_object_a,sat_object_b)
    end

  elseif sat_object_b.type == "poly" then
    return SAT.circle_poly(sat_object_a,sat_object_b)

  else

    return SAT.circle_circle(sat_object_a,sat_object_b)
  end

end

-- Determine is two circle are colliding.
-- @c_a : table, sat_object
-- @c_b : table, sat_object
-- return : boolean, mtv_axis, overlap , point_of_collision
function SAT.circle_circle(c_a, c_b)
  -- Gets the vector between the two positions
  local v1 = vector.substract(c_a.position,c_b.position)
  -- Gets its magnitude
  local d =  vector.magnitude(v1)
  -- Gets the distance total of the addition of both radius
  local radius_plus_radius = c_a.radius + c_b.radius


  -- If the mangitude of the vector if less than the radius, the circles collides
  if ( d < radius_plus_radius) then
    -- Collide
    local mtv_axis = vector.normalize(v1)
    local mtv = radius_plus_radius - d

    local point_of_collision = vector.addition( c_a.position, vector.multiply(vector.multiply(mtv_axis,-1),c_a.radius- mtv))
    return true, mtv_axis, mtv, point_of_collision
  end
  -- Not colliding
  return false
end


-- Determine is a circle is colliding with a poly shape.
-- @sat_object_a : table, sat_object
-- @sat_object_b : table, sat_object
-- return : boolean, mtv_axis, overlap , point_of_collision
function SAT.circle_poly(sat_object_a, sat_object_b)
  local poly = {}
  local circle = {}

  if sat_object_a.type == "circle" then
    circle = sat_object_a
    poly = sat_object_b
  else
    circle = sat_object_b
    poly = sat_object_a
  end


  local axes = SAT.get_axes(poly.vertices)
  local vertex,index = SAT.found_nearest_vertex(circle.position, poly.vertices)

  -- The last axis, is the axis between the center of the circle to the nearest vertex of the polygon.
  local last_axis = vector.normalize(vector.substract(vertex,circle.position))
  table.insert(axes,last_axis)



  local overlap = 0
  local min_overlap = 0
  local mtv_axis_index = 1

  for i = 1 , #axes do

    local min_a,max_a = SAT.projection(circle, axes[i])
    local min_b,max_b = SAT.projection(poly, axes[i])
    -- As overlap return 0 or positive value, becase 0 or less mean no overlap
    overlap = math.line_overlap(min_a, max_a, min_b, max_b)

    if overlap == 0 then
      return false
    end
    if i == 1 then
      min_overlap = overlap
      mtv_axis_index = i
    else
      if overlap < min_overlap then
        min_overlap = overlap
        -- For the moment I only save the number of the axe in the table, but you have to return the correct axe
        mtv_axis_index = i
      end
    end
  end

  local p2_to_p1 = vector.substract(sat_object_a.position,sat_object_b.position)
  local mtv_axe = axes[mtv_axis_index]
  if vector.dot(p2_to_p1,mtv_axe) <= 0  then
    mtv_axe = vector.multiply(mtv_axe,-1)
  end






  local normal =  vector.normalize(vector.substract(poly.position,circle.position))
  local scalar_projection = vector.multiply(normal, circle.radius)
  local point_of_collision = vector.addition(circle.position, scalar_projection)
  return true, mtv_axe, min_overlap, point_of_collision



end


-- Project an object over an axis.
-- @sat_object : table, sat_object
-- @axis : table
-- return : min, max, they are the minum and maximum overlap of the shap along the axis.
function SAT.projection(sat_object, axis)
  local min,max = 0,0
  if sat_object.type == "circle" then
    local circle_pro = vector.dot(sat_object.position,axis)
    min = circle_pro - sat_object.radius
    max  = circle_pro + sat_object.radius
    return  min, max 
  end

  -- Polygon type
  min = vector.dot(sat_object.vertices[1],axis)
  max =  vector.dot(sat_object.vertices[1],axis)
  local pro = {}

  for i = 2, #sat_object.vertices do
    projection = vector.dot(sat_object.vertices[i],axis)
    if projection < min then
      min = projection
    elseif projection > max then
      max = projection
    end
  end

  return min,max


end

-- Test if a poly shape  A , has a seprating axis with an poly shape B
-- @sat_object_a : table, sat_object
-- @sat_object_b : table, sat_object_b
-- return : boolean, mtv_axis, overlap 
function SAT.poly_poly(sat_object_a, sat_object_b)

  -- Look for all the axis. Save it in the axes table, an array of axis.

  local axes,faces = SAT.get_axes(sat_object_a.vertices, true)
  local axes_b,faces_b = SAT.get_axes(sat_object_b.vertices, true)
  for i = 1, #axes_b do
    table.insert(axes,axes_b[i])
    table.insert(faces,faces_b[i])
  end

  -- Now loop over all axis, project all the vertices and see if there is an overlap
  -- If false, it can exits the loop early and return false
  -- Else if collide, all the axis has to be tested.

  local min_a = 0
  local max_a = 0

  local min_b = 0
  local max_b = 0

  local overlap = 0
  local min_overlap = 0


  local sat_a = false
  local sat_b = false

  -- The mtv axis, is the axis with the minimal translation vector needed to stop colliding.
  -- For the moment, only save it as an index.
  local mtv_axis_index = 1

  for i = 1, #axes do

    min_a,max_a = SAT.projection(sat_object_a,axes[i])
    min_b,max_b = SAT.projection(sat_object_b,axes[i])


    overlap = math.line_overlap(min_a, max_a, min_b, max_b)

    if overlap == 0 then
      return false
    end

    if i == 1 then
      min_overlap = overlap
    else
      if overlap <= min_overlap then
        -- Save the min_overlap, and the index of the axis
        min_overlap = overlap
        mtv_axis_index = i
      end
    end

  end

  -- The vector from the position of sat_object_b to sat_object_a. These vector will help to determine if the mtv_axis
  -- is the correct one, and not the inverse one. The mtv_axis has to be in the opposite direction of these new vector.
  local p2_to_p1 = vector.substract(sat_object_a.position,sat_object_b.position)
  local mtv_axis = axes[mtv_axis_index]
  local face_index = mtv_axis_index

  if vector.dot(p2_to_p1,axes[mtv_axis_index]) <= 0 then
    mtv_axis = vector.multiply(mtv_axis, -1)
  end
  return true, mtv_axis, min_overlap

end


return SAT