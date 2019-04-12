-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')
-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
love.graphics.setDefaultFilter("nearest")
if arg[#arg] == "-debug" then require("mobdebug").start() end















-- lib


local SAT = require("SAT")

-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).


function math.dist(point_a, point_b) return ((point_b[1]-point_a[1])^2+(point_b[2]-point_a[2])^2)^0.5 end

function math.rect_vertices(position, size, rotation)
  local vertices = {}
  local v = {}
  local w = size[1]/2
  local h = size[2]/2
  v1 = vector.rotate({ position[1]-w, position[2] - h},position, rotation)
  v2 = vector.rotate({ position[1]+w, position[2] - h},position, rotation)
  v3 = vector.rotate({position[1]+w, position[2] + h},position, rotation)
  v4 = vector.rotate({position[1]-w,  position[2] + h},position, rotation)

  table.insert(vertices,v1)
  table.insert(vertices,v2)
  table.insert(vertices,v3)
  table.insert(vertices,v4)
  return vertices
end




function poly_regular(n, r, origin)
  local poly = {}
  local angle = -math.rad(360/n)
  
  local v1 = {origin[1] + r,origin[2]}

      table.insert(poly, v1[1])
      table.insert(poly, v1[2])
    
    for i= 2 , n do
      local v2 = vector.rotate(v1, origin, angle*(i-1))
      table.insert(poly, v2[1])
      table.insert(poly, v2[2])
    end
  return {vertices = poly, position = origin}
end

local test = poly_regular(6, 50, {100,100})








function love.load()
  circles = {}
  rectangles = {}
  polys = {}
  my_rectangle = { position = { 600,  400}, size = { 50,  50}, rot = math.pi/4 }
  my_circle = { position = { 400,  100}, radius = 45 }
  
  
  for i=1, 0 do
    local poly = poly_regular(6,50,{50+i*150,300})
    
    table.insert(polys,poly)
  end
  
  
  
  for i=1, 0 do
    local circle = { position = {  100+(50*i-1),  200}, radius = 50 }
      table.insert(circles,circle)
  end


  for i=1, 1 do
    local rectangle =  { position = {50+(50*i-1), 400}, size = {150,25}, rot =math.pi/4}
    table.insert(rectangles,rectangle)
  end


  for i=1, 0 do
    local rectangle =  { position = {-50+(50*i-1), 100}, size = {25,25}, rot = math.pi/i*2}
    table.insert(rectangles,rectangle)
  end

  local point_inter = {}

end

local faces ={}


function love.update(dt)
  point_inter = {}
  faces = {}
  for i=1, #circles do
   -- local sat_1 = SAT.new_circle(my_circle.position,my_circle.radius )
    local sat_1 = SAT.new_poly(my_rectangle.position,math.rect_vertices(my_rectangle.position, my_rectangle.size,my_rectangle.rot))
    local sat_2 = SAT.new_circle(circles[i].position,circles[i].radius )
    
    --local collide, mtv_axis, mtv, point = SAT.circle_circle(sat_1,sat_2, true)
    local collide, mtv_axis, mtv, point = SAT.circle_poly(sat_1,sat_2, true)
   --local rectangle = {position = my_rectangle.position, vertices = math.rect_vertices(my_rectangle.position, my_rectangle.size,my_rectangle.rot)}
    --local collide, mtv_axis, mtv, point = SAT.circle_poly(circles[i],rectangle, true)
    if collide then
      table.insert(point_inter, point)
    end
  end

  for i=1, #rectangles do
   -- local sat_1 = SAT.new_circle(my_circle.position,my_circle.radius )
        local sat_1 = SAT.new_poly(my_rectangle.position,math.rect_vertices(my_rectangle.position, my_rectangle.size,my_rectangle.rot))
    local sat_2 = SAT.new_poly(rectangles[i].position, math.rect_vertices(rectangles[i].position, rectangles[i].size,rectangles[i].rot))

    
  local collide, mtv_axis, mtv, point, ff, sf = SAT.poly_poly(sat_1,sat_2, true)
    if collide then
      table.insert(faces,ff)
      table.insert(faces,sf)
     table.insert(point_inter, point)
    end
  end
  

  for i=1 , #polys do
   -- local sat_1 = SAT.new_circle(my_circle.position,my_circle.radius )
    local sat_1 = SAT.new_poly(my_rectangle.position,math.rect_vertices(my_rectangle.position, my_rectangle.size,my_rectangle.rot))
    local sat_2 = SAT.new_poly(polys[i].position, polys[i].vertices)
        
    local new_vertices = {}
    

    for j = 1, #polys[i].vertices, 2 do
      local v = { polys[i].vertices[j], polys[i].vertices[j+1]}
      table.insert(new_vertices,v)
      
    end
        
    sat_2.vertices = new_vertices
        
  local collide, mtv_axis, mtv, point, ff, sf = SAT.poly_poly(sat_1,sat_2, true)
    if collide then
      table.insert(faces,ff)
      table.insert(faces,sf)
     table.insert(point_inter, point)
    end
  end

  mouvement(my_rectangle)
  

end


function love.draw()
  
   love.graphics.print(love.timer.getFPS(), 10,10)
  for i = 1, #circles do
     love.graphics.circle("line", circles[i].position[1], circles[i].position[2], circles[i].radius)
  end
  
  for i =1, #rectangles do
    local vertices = math.rect_vertices(rectangles[i].position,rectangles[i].size,rectangles[i].rot)
    local v = {}
    for i=1, #vertices do
      table.insert(v,vertices[i][1])
      table.insert(v, vertices[i][2])
    end
    love.graphics.polygon("line",v)

end

 love.graphics.setColor(1,0,0,1)
  for i=1, #point_inter do
    love.graphics.rectangle("fill", point_inter[i][1]-5,point_inter[i][2]-5,10,10)
  end
 love.graphics.setColor(1,1,1,1)
 -- love.graphics.circle("line",my_circle.position[1], my_circle.position[2], my_circle.radius)
 
 for i = 1, #polys do
   
   love.graphics.polygon("line",polys[i].vertices)
  end


  local vertices = math.rect_vertices(my_rectangle.position,my_rectangle.size,my_rectangle.rot)

  
  local v = {}
  
    for i=1, #vertices do
            table.insert(v,vertices[i][1])
      table.insert(v, vertices[i][2])
      
    end
  
      love.graphics.polygon("line",v)

      
            love.graphics.setColor(1,0,0,1)
            
            
  for i =1, #faces do

    love.graphics.line(faces[i][1][1],faces[i][1][2],faces[i][2][1],faces[i][2][2])
  end
  
      love.graphics.setColor(1,1,1,1)
      
      
      
      

      local x,y = love.mouse:getPosition()
      
      
      love.graphics.print(x.."  "..y, 20,20)
end



function mouvement(objet)
  if love.keyboard.isDown("z") then
  objet.rot = objet.rot+   math.rad(1)
  
end

  if love.keyboard.isDown("s") then
  objet.rot = objet.rot+   math.rad(-1)
  
end
  if love.keyboard.isDown("up") then
  objet.position[2] =   objet.position[2] - 5
  
  end
  
    if love.keyboard.isDown("down") then
    objet.position[2] =   objet.position[2] + 5
  
  end
  if love.keyboard.isDown("right") then
    objet.position[1] =   objet.position[1] + 5
    
  end
  if love.keyboard.isDown("left") then
      objet.position[1] =   objet.position[1] - 5
  
  end
end