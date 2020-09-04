export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("chat", function () {
      this.route("provider", { path: "/:provider" });
    });
  },
};
