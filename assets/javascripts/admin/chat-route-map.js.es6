export default {
  resource: 'admin.adminPlugins',
  path: '/plugins',
  map() {
    this.route('chat', function(){
    	this.route('index', { 'path': '/' });
    	this.route('provider', {path: '/:provider'});
    });
  }
};