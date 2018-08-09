exports.files = {
	javascripts: {
		joinTo: {
			'vendor.js': /^node_modules/,
			'app.js': /^app/
		}
	},
	stylesheets: {
		joinTo: {
			'vendor.css': /^node_modules/,
			'app.css': /^app/
		}
	}
};

exports.npm = {
	styles: {
		nouislider: ["distribute/nouislider.css"]
	}
};

exports.plugins = {
	babel: { presets: ['env'] },
	coffee: { bare: true }
};
