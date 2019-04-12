function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end
local vector = {}


-- 
function vector.addition(v1,v2) return {v1[1]+v2[1],v1[2]+v2[2]} end


-- Substract two vectors, for the moment it must int meh
function vector.substract_vector(v1, v2) return {v1[1]-v2[1],v1[2]-v2[2]} end

-- Multiply a vector by a scalar
function vector.multiply_vector(vector, scale) return {vector[1] *scale, vector[2] * scale} end

-- Dot product between two vector
function vector.dot(v1,v2) return v1[1]*v2[1] + v1[2]*v2[2] end


function vector.magnitude(v1) return math.sqrt(v1[1]*v1[1] + v1[2]*v1[2]) end

function vector.is_para(v1, v2)
  if math.round(v1[1]*v2[2]) == math.round(v1[2]*v2[1]) then
    return true
  end
  
  return false
  
end



function vector.normalize(v1)  
  local unit = vector.magnitude(v1)

  return {v1[1]/unit, v1[2]/unit }
end


function vector.reflection(vecteur, normal)
  local scalaire = 2 * math.dot(vecteur, normal)

  local vecteur_r = vector.substract_vector(vecteur,{x = scalaire*normal.x, y = scalaire*normal.y})

  return vecteur_r
end


-- Can be used to rotate a point as long the origin is 0,0
function vector.rotate(vecteur, origin, angle)
  local sinus = math.sin(-angle)
  local cosinus = math.cos(-angle)

  local x1 = vecteur[1] - origin[1]
  local y1 = vecteur[2] - origin[2]
   x = math.round(x1 * cosinus - y1 *sinus,2)
   y  = math.round(x1 * sinus + y1 * cosinus,2)



  local new_vector = { x + origin[1],y +origin[2]  }

  return new_vector
end








return vector