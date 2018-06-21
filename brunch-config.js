exports.files = {
	javascripts: {
		joinTo: {
			'vendor.js': /^node_modules/,
			'app.js': /^app/
		}
	},
	stylesheets: { joinTo: 'app.css' }
};

exports.plugins = {
	babel: { presets: ['env'] },
	coffee: { bare: true }
};
