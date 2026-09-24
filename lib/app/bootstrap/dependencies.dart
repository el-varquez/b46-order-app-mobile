import '../../core/config/app_config.dart';
import '../../core/networking/json_http_client.dart';
import '../../core/networking/session_access.dart';
import '../../core/storage/secure_key_value_store.dart';
import '../../features/authentication/application/use_cases/session_use_cases.dart';
import '../../features/admin_cashier_management/application/use_cases/admin_cashier_use_cases.dart';
import '../../features/admin_cashier_management/data/repositories/admin_cashier_repository_impl.dart';
import '../../features/admin_cashier_management/data/sources/admin_cashier_remote_source.dart';
import '../../features/admin_cashier_management/presentation/cubit/admin_cashiers_cubit.dart';
import '../../features/authentication/application/use_cases/registration_use_cases.dart';
import '../../features/authentication/data/repositories/session_repository_impl.dart';
import '../../features/authentication/data/sources/session_sources.dart';
import '../../features/authentication/domain/entities/session.dart';
import '../../features/authentication/presentation/cubit/session_cubit.dart';
import '../../features/authentication/presentation/cubit/registration_cubit.dart';
import '../../features/cart_checkout/application/use_cases/update_cart.dart';
import '../../features/cart_checkout/data/repositories/memory_cart_repository.dart';
import '../../features/cart_checkout/presentation/cubit/cart_cubit.dart';
import '../../features/cashier_fulfillment/application/use_cases/cashier_use_cases.dart';
import '../../features/cashier_fulfillment/data/repositories/cashier_repository_impl.dart';
import '../../features/cashier_fulfillment/data/sources/cashier_remote_source.dart';
import '../../features/cashier_fulfillment/presentation/cubit/cashier_orders_cubit.dart';
import '../../features/catalog/application/use_cases/load_products.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/data/sources/catalog_remote_source.dart';
import '../../features/catalog/presentation/cubit/catalog_cubit.dart';
import '../../features/customer_orders/application/use_cases/customer_order_use_cases.dart';
import '../../features/customer_orders/data/repositories/customer_order_repository_impl.dart';
import '../../features/customer_orders/data/sources/customer_order_remote_source.dart';
import '../../features/customer_orders/presentation/cubit/customer_orders_cubit.dart';
import '../theme/theme_cubit.dart';
import 'google_method_channel_auth.dart';

final class AppDependencies {
  AppDependencies._({
    required this.config,
    required this.session,
    required this.registration,
    required this.theme,
    required this.catalog,
    required this.cart,
    required this.customerOrders,
    required this.cashierOrders,
    required this.adminCashiers,
    required this.cashierOrderDetails,
  });

  factory AppDependencies.create(AppConfig config) {
    final rawHttp = JsonHttpClient(baseUrl: config.apiBaseUrl);
    final access = SessionAccess();
    final sessionRepository = SessionRepositoryImpl(
      remote: SessionRemoteSource(rawHttp),
      local: SessionLocalSource(PlatformSecureKeyValueStore()),
      access: access,
      providers: {
        OAuthProvider.google: GoogleCredentialSource(
          native: const GoogleMethodChannelAuth(),
          clientId: config.googleClientId,
          serverClientId: config.googleServerClientId,
        ),
      },
    );
    final api = AuthenticatedApiClient(rawHttp, access);
    final catalogRepository = CatalogRepositoryImpl(CatalogRemoteSource(api));
    final orderRepository = CustomerOrderRepositoryImpl(
      CustomerOrderRemoteSource(api),
    );
    final cashierRepository = CashierRepositoryImpl(CashierRemoteSource(api));
    final adminRepository = AdminCashierRepositoryImpl(
      AdminCashierRemoteSource(api),
    );
    final cartRepository = MemoryCartRepository();
    final session = SessionCubit(
      restoreSession: RestoreSession(sessionRepository),
      passwordLogin: PasswordLogin(sessionRepository),
      oauthLogin: OAuthLogin(sessionRepository),
      signOut: SignOut(sessionRepository),
      changePassword: ChangeOwnPassword(sessionRepository),
    );
    final registration = RegistrationCubit(
      begin: BeginRegistration(sessionRepository),
      resend: ResendRegistration(sessionRepository),
      verify: VerifyRegistration(sessionRepository),
      onVerified: session.acceptVerifiedRegistration,
    );
    access.onInvalidated(session.sessionInvalidated);
    return AppDependencies._(
      config: config,
      session: session,
      registration: registration,
      theme: ThemeCubit(),
      catalog: CatalogCubit(LoadProducts(catalogRepository)),
      cart: CartCubit(UpdateCart(cartRepository)),
      customerOrders: CustomerOrdersCubit(
        place: PlaceCustomerOrder(orderRepository),
        loadOrder: LoadCustomerOrder(orderRepository),
        loadOrders: LoadCustomerOrders(orderRepository),
        ids: const UuidCheckoutIdGenerator(),
        pollInterval: config.pollInterval,
      ),
      cashierOrders: CashierOrdersCubit(
        LoadCashierOrders(cashierRepository),
        config.pollInterval,
      ),
      adminCashiers: AdminCashiersCubit(
        list: ListCashiers(adminRepository),
        detail: LoadCashier(adminRepository),
        beginRegistration: BeginCashierRegistration(adminRepository),
        resendRegistration: ResendCashierRegistration(adminRepository),
        verifyRegistration: VerifyCashierRegistration(adminRepository),
        changeStatus: ChangeCashierStatus(adminRepository),
        resetLogin: ResetCashierLogin(adminRepository),
      ),
      cashierOrderDetails: () => CashierOrderDetailCubit(
        load: LoadCashierOrder(cashierRepository),
        markRead: MarkCashierOrderRead(cashierRepository),
        advance: AdvanceCashierOrder(cashierRepository),
      ),
    );
  }

  final AppConfig config;
  final SessionCubit session;
  final RegistrationCubit registration;
  final ThemeCubit theme;
  final CatalogCubit catalog;
  final CartCubit cart;
  final CustomerOrdersCubit customerOrders;
  final CashierOrdersCubit cashierOrders;
  final AdminCashiersCubit adminCashiers;
  final CashierOrderDetailCubit Function() cashierOrderDetails;

  Future<void> close() async {
    await session.close();
    await registration.close();
    await theme.close();
    await catalog.close();
    await cart.close();
    await customerOrders.close();
    await cashierOrders.close();
    await adminCashiers.close();
  }
}
