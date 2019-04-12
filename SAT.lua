
vector = require("lib.vector")

function math.dist(point_a, point_b) return ((point_b[1]-point_a[1])^2+(point_b[2]-point_a[2])^2)^0.5 end

function math.line_overlap(a_min, a_max, b_min, b_max)

  local min1 = math.min(a_max,b_max)
  local max1 = math.max(a_min,b_min)

  local diff = min1-max1
  diff = math.floor(diff)
  return math.max(0,diff)

end

-- Separating Axis theorem, for detect collision between oriented objetcs
-- Three main functions :
--  circle_cirlce 
--  circle_poly
--  poly_poly
-- All these three functions can return the point of intersection if mode == true


local SAT = {}

-- Create a new SAT object. At first I didn"t want to this, but for the function circle_poly I needed the object to be passe in the
-- same order, the colider in first position, or these function could be use with a circle collider or a polygon circle.
-- @position : table
-- @type : string; circle, polygone
function SAT.new_body( position, shape_type)
  assert(type(position) == "table")
  assert(type(shape_type) == "string")
  local new_body = { position = position, type = shape_type}
  return new_body
end


function SAT.new_circle(position, radius)
  local new_circle = SAT.new_body(position, "circle")
  new_circle.radius = radius

  return new_circle
end

function SAT.new_poly(position, vertices)
  local new_poly = SAT.new_body(position, "poly")
  new_poly.vertices = vertices

  return new_poly

end




-- @position : table
-- @vertices : table
-- return : the vertex the nearest 
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


-- @vertices : table
-- @faces_mod : boolean , if true, it will return the edge associated to the axis
-- return : table of all axis found for theses vertices and the faces associated are optionnal
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
    normal = vector.normalize(vector.substract_vector(v2,v1))
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




function SAT.found_nearest_edge(face, vertices)
  local v1 = vertices[1]
  local v2 = vertices[2]
  local face_vector = vector.substract_vector(face[2],face[1])
  
  local dot = vector.dot(vector.substract_vector(v2, v1), face_vector)
  local min_dot = dot
  local second_face = {v2, v1}
  local index = 1
  for i = 2, #vertices do
    v1  = vertices[i]
    v2  = vertices[i+1 == #vertices+1 and 1 or i+1]
    dot = vector.dot(vector.substract_vector(v2,v1),face_vector)
    if dot < min_dot then
      min_dot = dot
      index = i
      second_face =  {v1, v2}
    end
  end

  return second_face, index
end



function SAT.circle_circle(c_a, c_b, mode)
  -- Gets the vector between the two positions
  local v1 = vector.substract_vector(c_a.position,c_b.position)
  -- Gets its magnitude
  local d =  vector.magnitude(v1)
  -- Gets the distance total of the addition of both radius
  local radius_plus_radius = c_a.radius + c_b.radius
  -- If the mangitude of the vector if less than the radius, the circles collides


  if ( d < radius_plus_radius) then
    -- Collide
    local mtv_axis = vector.normalize(v1)
    local mtv = radius_plus_radius - d

    if mode then
      local point = vector.addition( c_a.position, vector.multiply_vector(vector.multiply_vector(mtv_axis,-1),c_a.radius- mtv))
      return true, mtv_axis, mtv,point
    else
      return true, mtv_axis, mtv
    end
  end
  -- Not collide
  return false
end


-- body
function SAT.circle_poly(sat_object_a, sat_object_b, mode)
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
  local last_axis = vector.normalize(vector.substract_vector(vertex,circle.position))
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

  local p2_to_p1 = vector.substract_vector(sat_object_b.position,sat_object_a.position)
  local mtv_axe = axes[mtv_axis_index]
  if vector.dot(p2_to_p1,mtv_axe) <= 0  then
    mtv_axe = vector.multiply_vector(mtv_axe,-1)
  end
  
  
  
  

  if mode then
    local normal =  vector.normalize(vector.substract_vector(poly.position,circle.position))
    local scalar_projection = vector.multiply_vector(normal, circle.radius)
    local point = vector.addition(circle.position, scalar_projection)
    
    return true, axes[mtv_axis_index], min_overlap, point
  else
    return true, axes[mtv_axis_index], min_overlap
  end


end



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

-- Test if an object A , has a seprating axis with an object B
-- It uses the Separating Axis Theorem
-- Note : If one or both objetcs are rectangles, you should only three vertices, to get only two axis, it's enough for 
-- rectangles
-- @sat_object_a : array of position, vertices, type
-- @sat_object_b : array of position, vertices, type
-- @is_point_need : bool, if false, don't return the point of collision,  it's faster.
-- return
function SAT.poly_poly(sat_object_a, sat_object_b, is_point_needed)

  -- First, we look for all the axis. I save it in the axes table, an array of axis
  -- If the point is_point_needed, we will get the faces too, it will be use later, to determinethe intersection point

  local axes,faces = SAT.get_axes(sat_object_a.vertices, true)
  local axes_b,faces_b = SAT.get_axes(sat_object_b.vertices, true)
  for i = 1, #axes_b do
    table.insert(axes,axes_b[i])
    table.insert(faces,faces_b[i])
  end

  -- Now you I loop over all my axis, project all the vertices and see if there is an overlap
  -- If false, I can exit the loop early and return false
  -- Else if collide, all the axis has to be tested

  local min_a = 0
  local max_a = 0

  local min_b = 0
  local max_b = 0

  local overlap = 0
  local min_overlap = 0


  local sat_a = false
  local sat_b = false

  -- The mtv axis or , the axis with the minimil translation vector. Wich axis need the litle amount of effort to avoid collision
  -- For the moment we will save it as the index of the axes table
  local mtv_axis_index = 1

  for i = 1, #axes do

    min_a,max_a = SAT.projection(sat_object_a,axes[i])
    min_b,max_b = SAT.projection(sat_object_b,axes[i])

    -- As overlap return 0 or positive value, becase 0 or less mean no overlap
    overlap = math.line_overlap(min_a, max_a, min_b, max_b)


    --print(i)
    --print(axes[i][1],axes[i][2])
    --print(min_a, max_a, min_b, max_b,overlap)
    if overlap == 0 then
      return false
    end

    if i == 1 then
      min_overlap = overlap
      sat_a = true
      sat_b = false
    else
      if overlap < min_overlap then
        -- Save the min_overlap, and the index of the axis
        min_overlap = overlap
        mtv_axis_index = i

        if i <= #sat_object_a.vertices then
          sat_a = true
          sat_b = false
        else
          sat_a = false
          sat_b = true
        end

      end
    end

  end

  -- The vector from the position of sat_object_b to sat_object_a. These vector will help us to determine if the mtv_axis
  -- is the correct one, and not the inverse one. The mtv_axis has to be in the opposite direction of these new vector.
  local p2_to_p1 = vector.substract_vector(sat_object_a.position,sat_object_b.position)

  local face_index = mtv_axis_index

  if vector.dot(p2_to_p1,axes[mtv_axis_index]) <= 0 then
    if sat_a then
      mtv_axis_index = mtv_axis_index +2 > #sat_object_a.vertices and 1 or  mtv_axis_index +2 

  else
    local pas = (#sat_object_b.vertices/2)
      mtv_axis_index = mtv_axis_index +pas > #sat_object_b.vertices+#sat_object_a.vertices and #sat_object_a.vertices+#sat_object_a.vertices+1 or  mtv_axis_index +pas 
      face_index = mtv_axis_index
    end


  else
    -- I don't explain these part yet, but it works
    if sat_a then
      face_index = mtv_axis_index +2 > #sat_object_a.vertices and 1 or  mtv_axis_index +2 
    end

  end





  --print(axes[mtv_axis_index][1],axes[mtv_axis_index][2])

  if mode then
    return true, axes[mtv_axis_index], min_overlap
  end


-- If we are here, the entities collide and we have found the axis associated with the mtv
-- Now we need to found : the faces involved and the point of collision

-- The first face, it's the face from the sat_object where the mtv_axis is from
  local first_face = faces[face_index]

-- Thrase case are possible, the collision is type :
-- vertex - vertex
-- vertex - edge
-- edge - edge
-- The vertices cases, will be treat as same, we juste need to found the second face a if it's not parallele to the first one
-- take the nearest vertex.
-- Ohterwise if it's edge - edge.

  local second_face = {}
  if sat_a then
      -- First face is on sat_object_a
    second_face = SAT.found_nearest_edge(first_face, sat_object_b.vertices)
  else
      -- First face is on sat_object_b
    second_face = SAT.found_nearest_edge(first_face, sat_object_a.vertices)
  end
  
  -- Now test is the face are orthogonal
  local v1 = vector.substract_vector(first_face[2],first_face[1])
  local v2 = vector.substract_vector(second_face[2],second_face[1])
  
  local point = {}
  if  vector.is_para(v1,v2) then
    point = {(first_face[1][1] + first_face[2][1])/2, (first_face[1][2] + first_face[2][2])/2}
  else
    -- return the nearest point 

   if sat_a then
      local ax = vector.multiply_vector(  axes[mtv_axis_index],-1)
      if vector.dot(ax, second_face[1]) < vector.dot(ax, second_face[2]) then
        point = second_face[1]
      else
        point = second_face[2]
      end
 --    point =  SAT.found_nearest_vertex(sat_object_a.position, second_face)
     
    else
      if vector.dot(axes[mtv_axis_index], second_face[1]) < vector.dot(axes[mtv_axis_index], second_face[2]) then
        point = second_face[1]
      else
        point = second_face[2]
      end
 --    point =  SAT.found_nearest_vertex(sat_object_a.position, second_face)
     --point =  SAT.found_nearest_vertex(sat_object_b.position, second_face)
     
   -- point = vector.addition(point, vector.multiply_vector(axes[mtv_axis_index],min_overlap))
  end
  
  
  
  end



-- The faces are optionals, but usefull for debug graphic information

 --print(min_overlap, axes[mtv_axis_index][1],axes[mtv_axis_index][2])
  return true, min_overlap, axes[mtv_axis_index], point, first_face,second_face



end


return SAT