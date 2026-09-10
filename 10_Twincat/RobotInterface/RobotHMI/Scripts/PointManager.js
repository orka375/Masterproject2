(function () {
    'use strict';

    function bind(sourceControlId, listExpression, frameExpression) {
        var sourceControl = TcHmi.Controls.get(sourceControlId);
        var root = sourceControl ? sourceControl.getElement().closest('[data-tchmi-type="TcHmi.Controls.System.TcHmiUserControl"]') : null;
        var element = root && root.length ? root.find('[id$="PointManagerPointSelector"]') : null;
        var selector = element && element.length ? TcHmi.Controls.get(element.attr('id')) : null;
        var frameElement = root && root.length ? root.find('[id$="PointManagerReferenceFrameEdited"]') : null;
        var frameSelector = frameElement && frameElement.length ? TcHmi.Controls.get(frameElement.attr('id')) : null;
        if (!selector || !frameSelector) {
            return null;
        }

        var listWatch = new TcHmi.Symbol(listExpression).watch(function (data) {
            var source = data && data.error === TcHmi.Errors.NONE && Array.isArray(data.value) ? data.value : [];
            var seenIds = Object.create(null);
            var items = [];

            for (var index = 0; index < source.length; index++) {
                var entry = source[index];
                var id = entry ? Number(entry.id) : 0;
                var text = entry && typeof entry.text === 'string' ? entry.text : '';
                var idKey = String(id);

                if (id > 0 && text !== '' && !seenIds[idKey]) {
                    seenIds[idKey] = true;
                    items.push({ id: id, text: text, value: entry.value });
                }
            }

            selector.setSrcData(items);
        });

        var frameWatch = new TcHmi.Symbol(frameExpression).watch(function (data) {
            if (data && data.error === TcHmi.Errors.NONE && data.value !== undefined && data.value !== null) {
                frameSelector.setSelectedId(Number(data.value));
            }
        });

        return { listWatch: listWatch, frameWatch: frameWatch };
    }

    window.PointManager = {
        bind: bind
    };
})();
