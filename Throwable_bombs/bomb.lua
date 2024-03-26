local S = minetest.get_translator(minetest.get_current_modname())

mobs:register_arrow("throwable_bombs:bomb", {
	visual = "sprite",
	visual_size = {x = 1, y = 1},
	textures = {"transparent.png"},
	velocity = 8,
        hit_player = function(self, player)
	end,

	on_step = function(self, dtime)

		local pos = self.object:get_pos()

		if minetest.is_protected(pos, "") then
			return
		end

		local n = minetest.get_node(pos).name

		if self.timer == 0 then
			self.timer = os.time()
		end

		if os.time() - self.timer > 5 or minetest.is_protected(pos, "")
		or ((n ~= "air") and (n ~= "tnt:tnt_burning")) then
			self.object:remove()
		end

		if math.random(2) == 2 then
			minetest.set_node(pos, {name = "tnt:tnt_burning"})
		end

		if math.random(6) == 1 then

			local p = {
				x = pos.x + math.random(-1, 1),
				y = pos.y + math.random(-1, 1),
				z = pos.z + math.random(-1, 1)
			}

			local n = minetest.get_node(p).name

			if n == "air" then
				minetest.set_node(p, {name = "tnt:tnt_burning"})
			end
		end
	end
})
--if minetest.get_modpath("special_nether_swords") then
mobs:register_arrow("throwable_bombs:bomb_arrow", {
	visual = "sprite",
	visual_size = { x = 0.5, y = 0.5 },
	textures = { "tnt_tnt_stick.png" },
	velocity = 18, -- Nodes per second
	physical = true,
	collide_with_objects = true,
	
		on_step = function(self, dtime)

		local pos = self.object:get_pos()

		if minetest.is_protected(pos, "") then
			return
		end

		local n = minetest.get_node(pos).name

		if self.timer == 0 then
			self.timer = os.time()
		end

		if os.time() - self.timer > 5 or minetest.is_protected(pos, "")
		or ((n ~= "air") and (n ~= "tnt:tnt_burning")) then
			self.object:remove()
		end

		if math.random(2) == 2 then
			minetest.set_node(pos, {name = "tnt:tnt_burning"})
		end

		if math.random(6) == 1 then

			local p = {
				x = pos.x + math.random(-1, 1),
				y = pos.y + math.random(-1, 1),
				z = pos.z + math.random(-1, 1)
			}

			local n = minetest.get_node(p).name

			if n == "air" then
				minetest.set_node(p, {name = "tnt:tnt_burning"})
			end
		end
	end
})

minetest.register_tool("throwable_bombs:bomb_gun", {
	description = "tnt gun (shoots tnt)",
	short_description = "Bombs gun",
	inventory_image = "default_stick.png",
	groups = { not_in_creative_inventory = 1 },
	on_use = function(itemstack, user, pointed_thing)
		if not minetest.is_player(user) then
			return
		end

		local pos = user:get_pos()
		local dir = user:get_look_dir()
		local vel = user:get_velocity()

		local epos = vector.add(pos, vector.add({ x = 0, y = 1, z = 0 }, vector.multiply(dir, 2)))

		local obj = minetest.add_entity(epos, "throwable_bombs:bomb_arrow")
		if not obj then
			return
		end

		obj:set_velocity(vector.add(vel, vector.multiply(dir, 18)))

		local ent = obj:get_luaentity()
		if not ent then
			obj:remove()
			return
		end

		ent.switch = 1

		local yaw = user:get_look_horizontal()
		obj:set_yaw(yaw + math.pi / 2)
	end,
})

minetest.register_craftitem("throwable_bombs:throwable_tnt_spawner", {
	description = "Throwable Tnt Spawner",
	range = 0,
	stack_max= 16,
	inventory_image = "tnt_tnt_stick.png",
	on_use = function(itemstack, user, pointed_thing)
			if not minetest.setting_getbool("creative_mode") then itemstack:take_item()
		end
		if pointed_thing.type ~= "nothing" then
			local pointed = minetest.get_pointed_thing_position(pointed_thing)
			if vector.distance(user:getpos(), pointed) < 8 then
				return itemstack
			end
		end
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir then
			pos.y = pos.y + 1.5
			local obj = minetest.add_entity(pos, "throwable_bombs:bomb_arrow")
			if obj then
				obj:setvelocity({x=dir.x * 35, y=dir.y * 35, z=dir.z * 35})
				obj:setacceleration({x=dir.x * -3, y=-10, z=dir.z * -3})
				obj:setyaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
				end
			end
		end
		return itemstack
	end,
})

local function bombs_register_throwitem(name, descr, def)

	minetest.register_craftitem("throwable_bombs:" .. name .. "_bomb", {
		description = descr,
		inventory_image = name .. "_bomb.png",

		on_use = function(itemstack, placer, pointed_thing)

			--weapons_shot(itemstack, placer, pointed_thing, def.velocity, name)
			local velocity = 15
			local dir = placer:get_look_dir()
			local playerpos = placer:get_pos()

			posthrow = playerpos

			local obj = minetest.add_entity({
				x = playerpos.x + dir.x,
				y = playerpos.y + 2 + dir.y,
				z = playerpos.z + dir.z
			}, "throwable_bombs:" .. name .. "_bomb_flying")

			local vec = {x = dir.x * velocity, y = dir.y * velocity, z = dir.z * velocity}
			local acc = {x = 0, y = -9.8, z = 0}

			obj:set_velocity(vec)
			obj:set_acceleration(acc)

			itemstack:take_item()

			return itemstack
		end
	})

	minetest.register_entity("throwable_bombs:" .. name .. "_bomb_flying", {
		textures = {name .. "_bomb.png"},
		hp_max = 20,
		collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},

		on_step = function(self, dtime)

			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			local n = node.name

			if n ~= "air" then
				def.hit_node(self, pos)
				self.object:remove()
			end
		end
	})
end

bombs_register_throwitem("smoke", "Smoke Bomb", {

	hit_node = function(self,pos)

		local pos1 = {x = pos.x, y = pos.y, z = pos.z}

		minetest.add_particlespawner({
			amount = 4500,
			time = 20,
			minpos = {x = pos1.x - 3, y = pos1.y + 0.5, z = pos1.z - 3},
			maxpos = {x = pos1.x + 3, y = pos1.y + 0.5, z = pos1.z + 3},
			minvel = {x = 0.2, y = 0.2, z = 0.2},
			maxvel = {x = 0.4, y = 0.8, z = 0.4},
			minacc = {x = -0.2, y = 0, z = -0.2},
			maxacc = {x = 0.2, y = 0.1, z = 0.2},
			minexptime = 6,
			maxexptime = 8,
			minsize = 10,
			maxsize = 12,
			collisiondetection = false,
			vertical = false,
			texture = "tnt_smoke.png"
		})
	end
})

bombs_register_throwitem("smoke_dense", "Dense Smoke Bomb", {

	hit_node = function(self,pos)

		local pos1 = {x = pos.x, y = pos.y, z = pos.z}

		minetest.add_particlespawner({
			amount = 15000,
			time = 60,
			minpos = {x = pos1.x - 7, y = pos1.y + 0.6, z = pos1.z - 7},
			maxpos = {x = pos1.x + 7, y = pos1.y + 0.5, z = pos1.z + 7},
			minvel = {x = 0.2, y = 0.2, z = 0.2},
			maxvel = {x = 0.4, y = 0.8, z = 0.4},
			minacc = {x = -0.2, y = 0, z = -0.2},
			maxacc = {x = 0.2, y = 0.1, z = 0.2},
			minexptime = 6,
			maxexptime = 8,
			minsize = 10,
			maxsize = 12,
			collisiondetection = false,
			vertical = false,
			texture = "tnt_smoke.png"
		})
	end
})


