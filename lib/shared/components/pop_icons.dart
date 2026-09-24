import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// App icon vocabulary. Add new Lucide icons here before using them in screens.
abstract final class PopIcons {
  static const IconData back = LucideIcons.chevronLeftDir;
  static const IconData forward = LucideIcons.chevronRightDir;
  static const IconData theme = LucideIcons.sunMoon;
  static const IconData showPassword = LucideIcons.eye;
  static const IconData hidePassword = LucideIcons.eyeOff;
  static const IconData signOut = LucideIcons.logOut;
  static const IconData orders = LucideIcons.receiptText;
  static const IconData basket = LucideIcons.shoppingBag;
  static const IconData emptyShelf = LucideIcons.store;
  static const IconData drink = LucideIcons.cupSoda;
  static const IconData pantry = LucideIcons.cookingPot;
  static const IconData groceries = LucideIcons.shoppingBasket;
  static const IconData remove = LucideIcons.trash2;
  static const IconData decrease = LucideIcons.circleMinus;
  static const IconData increase = LucideIcons.circlePlus;
  static const IconData preparing = LucideIcons.package;
  static const IconData delivering = LucideIcons.truck;
  static const IconData delivered = LucideIcons.circleCheck;
  static const IconData rejected = LucideIcons.packageX;
  static const IconData users = LucideIcons.users;
  static const IconData addUser = LucideIcons.userPlus;
  static const IconData disableUser = LucideIcons.userRoundX;
  static const IconData restoreUser = LucideIcons.userCheck;
  static const IconData resetLogin = LucideIcons.keyRound;
}
