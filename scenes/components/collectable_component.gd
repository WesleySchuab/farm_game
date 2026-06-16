class_name CollectableComponent
extends Area2D

@export var collectable_name: String



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		InventoryManager.add_collectable(collectable_name)
		print("chama a fç add_collectable")
		print("Collected ", collectable_name)
		get_parent().queue_free()
		
# CHECAGEM SIMPLES: Se for um animal, cura o jogador na hora!
		if collectable_name == "cow":
			body.adicionar_vida(30.0) # Vaca dá leite/carne (cura 30)
			print("Você coletou recursos da Vaca e recuperou vida!")
			
		elif collectable_name == "chicken":
			body.adicionar_vida(15.0) # Galinha dá ovo/carne (cura 15)
			print("Você coletou recursos da Galinha e recuperou vida!")			
		elif collectable_name == "milk":
			body.adicionar_vida(15.0) # Galinha dá ovo/carne (cura 15)
			print("Você coletou recursos da milk e recuperou vida!")	
		elif collectable_name == "egg":
			body.adicionar_vida(15.0) # Galinha dá ovo/carne (cura 15)
			print("Você coletou recursos da egg e recuperou vida!")
			
		else:
			# Se NÃO for vaca nem galinha (ex: madeira, pedra, tomate), vai para o inventário
			InventoryManager.add_collectable(collectable_name)
			print("Item enviado para o inventário: ", collectable_name)
		
		# De qualquer forma, remove o objeto coletado do mapa
		get_parent().queue_free()
