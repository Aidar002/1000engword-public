extends Control


@onready var animation_player = $"../AnimationPlayer"
const APPLICATION_ID = "2063646040"
const DEEPLINK_SCHEME = "org.godotengine.englishTest"
const PRODUCT_IDS = [
	"full_version",
	"support_dev"]
const FULL_VERSION_ID = 'full_version'
const DONAT_ID = 'support_dev'

#@onready var _loading = %loadingPage
var _core_client: RuStoreGodotCoreUtils = null
var _billing_client: RuStoreGodotBillingClient = null

func _ready():
#инициализация биллинга, нужно всегда
	_billing_client = RuStoreGodotBillingClient.get_instance()
	_billing_client.init(APPLICATION_ID, DEEPLINK_SCHEME, false)
	#это для проверки, авторизирован ли пользователь и сможет ли он что-то купить? т.е. у него есть rustore, он авторизован и т.п.
	_billing_client.on_get_authorization_status_success.connect(_on_get_authorization_status_success)
	_billing_client.on_get_authorization_status_failure.connect(_on_get_authorization_status_failure)
	#это для получения списка продуктов, которые есть в рустор консоли
	_billing_client.on_get_products_success.connect(_on_get_products_success)
	_billing_client.on_get_products_failure.connect(_on_get_products_failure)
	_billing_client.on_purchase_product_success.connect(_on_purchase_product_success)
	_billing_client.on_purchase_product_failure.connect(_on_purchase_product_failure)
	
	_billing_client.set_error_handling(true)
	_billing_client.set_theme(ERuStoreTheme.Item.DARK)
	#
	var is_rustore_installed: bool = _billing_client.is_rustore_installed()
	
	if is_rustore_installed:
		$Label.text = "RuStore is installed [v]"
	else:
		$Label.text = "RuStore is not installed [x]"
		
func _on_get_authorization_status_button_pressed():
	#_loading.visible = true
	_billing_client.get_authorization_status()
	
func _on_get_authorization_status_success(result: RuStoreBillingUserAuthorizationStatus):
	pass
	#_loading.visible = false
	#OS.alert(str(result.authorized), "UserAuthorizationStatus")
	#$Label.text = str(result.authorized)
	#result.free()
	
func _on_get_authorization_status_failure(error: RuStoreError):
	pass
	#_loading.visible = false
	#$Label.text = str(error.description)
	#error.free()
	
#func _on_tab_container_tab_clicked(tab):
	#match tab:
		#0:
			#_on_update_products_list_button_pressed()
		#1:
			#_on_update_purchases_list_button_pressed()
## Update products list
func _on_update_products_list_button_pressed():
	#_loading.visible = true
	_billing_client.get_products(PRODUCT_IDS)
	
func _on_get_products_success(products: Array):
	pass
	#for product in products:
		#$Label2.text = $Label2.text + '/n' + product.productId
	
	#_loading.visible = false
	#for product_panel in _products_list.get_children():
		#product_panel.queue_free()
	#
	#for product in products:
		#var product_panel: ProductPanel = load("res://scenes/product.tscn").instantiate()
		#_products_list.add_child(product_panel)
		#product_panel.set_product(product)
		#product_panel.on_purchase_product_pressed.connect(_on_purchase_product_pressed)
		
func _on_get_products_failure(error: RuStoreError):
	pass
	#_loading.visible = false
	#$Label.text = str(error.description) 
	#error.free()

func close_tab():
	animation_player.play("shop_down")

func _on_purchase_product_success(result: RuStorePaymentResult):
	animation_player.play("purchaseInfo_on")
	if result is RuStorePaymentResult.Success:
		%PurchaseResultInfo.text = "оплата прошла успешно"
	else:
		%PurchaseResultInfo.text = "возникла ошибка, либо невозможно установить статус покупки(попробуйте позже)"
	
func _on_purchase_product_failure(error: RuStoreError):
	pass


func _on_buy_full_button_pressed():
	_billing_client.purchase_product(FULL_VERSION_ID)


func _on_donat_button_pressed():
	_billing_client.purchase_product(DONAT_ID)


func _on_exit_button_pressed():
	animation_player.play("purchaseInfo_off")
