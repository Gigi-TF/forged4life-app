/// Whether the app shows money to members.
///
/// Driven by the server (`show_prices` on the menu and services responses),
/// so prices can be switched on the day they are agreed without an app
/// release.
///
/// Nothing here affects what is charged. Orders are still priced server-side,
/// discounts still apply, and staff still see real figures in the admin panel.
/// This only controls what a member is shown.
class Prices {
  static bool show = false;

  /// '$4.80' when prices are on, an empty string when they are not.
  static String of(double amount) =>
      show ? '\$${amount.toStringAsFixed(2)}' : '';
}
