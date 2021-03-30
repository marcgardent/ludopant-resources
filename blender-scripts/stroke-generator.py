#####################################
#HYPER-PARAMs
MATERIAL_NAME = 'strokes'
RESOLUTION = 6
RADIUS = 0.3
#####################################

import bpy
import bmesh
import mathutils
from collections import namedtuple
from math import cos, sin, pi

Ref = namedtuple("Ref", "origin uaxis vaxis")

def select_creases(mesh):
    for edge in mesh.edges:
        if edge.crease>0:
            yield (mesh.vertices[edge.vertices[0]].co, mesh.vertices[edge.vertices[1]].co)

def compute_axis2d(origin, a, b, c, d):
    uaxis = mathutils.Vector((c-b, a-c, b-a))
    vaxis = mathutils.Vector((a*(b+c)-b**2-c**2, b*(a+c)-a**2-c**2, c*(a+b)-a**2-b**2))
    uaxis.normalize()
    vaxis.normalize()
    return Ref(origin,uaxis, vaxis)

def circle(ref, radius, resolution):
    for step in range(0,resolution):
        angle = step/resolution * 2*pi
        yield mathutils.Vector(
        (ref.origin[0] + radius*cos(angle)*ref.uaxis[0] + radius*sin(angle)*ref.vaxis[0],
         ref.origin[1] + radius*cos(angle)*ref.uaxis[1] + radius*sin(angle)*ref.vaxis[1],
         ref.origin[2] + radius*cos(angle)*ref.uaxis[2] + radius*sin(angle)*ref.vaxis[2]
        ))

def face(target, vertices, material_index):
    f= target.faces.new(vertices)
    f.material_index = material_index
    return f

def edge_to_stroke(edge, target, resolution, radius, material_index):
    origin = edge[0]
    end = edge[1]
    normal = end - origin
        
    d = origin.dot(normal)
    a = normal[0] #x
    b = normal[1] #y
    c = normal[2] #z
    
    ref = compute_axis2d(origin, a,b,c,d)        
 
    
    circleOrigin = [target.verts.new(v) for v in circle(ref, radius, resolution)]
    circleDest = [target.verts.new(v+normal) for v in circle(ref, radius, resolution)]
    
    face(target,circleOrigin,material_index)
    face(target,circleDest,material_index)

    for step in range(0,resolution):
        vertices=(circleOrigin[step-1], circleDest[step-1],circleDest[step], circleOrigin[step])
        face(target, vertices,material_index)

def all_creases_to_strokes(data, resolution, radius, material_index):
    bm = bmesh.new()
    bm.from_mesh(data)
    for edge in select_creases(data):
        edge_to_stroke(edge, bm, resolution, radius, material_index)
    bm.to_mesh(data)
    bm.free()


def main():
    obj = bpy.context.active_object
    if obj.type == 'MESH':
        mesh = obj.data
        bpy.ops.object.mode_set(mode='OBJECT')
        material_index = bpy.data.materials.find(MATERIAL_NAME)
        if material_index>=0:
            if obj.material_slots.find(MATERIAL_NAME)<0:
                mesh.materials.append(bpy.data.materials[material_index])
            
            slot_index = obj.material_slots.find(MATERIAL_NAME)
            all_creases_to_strokes(mesh, RESOLUTION, RADIUS, slot_index)

main()
