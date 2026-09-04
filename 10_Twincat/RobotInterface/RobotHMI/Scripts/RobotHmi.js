/*
 * RobotHmi.js
 * ------------------------------------------------------------------
 * Robot context + hold-to-run jog manager for the Robot HMI.
 *
 * One page serves every robot. All robot-scoped elements are annotated
 * with data-* hooks that this module resolves against the currently
 * selected robot (SETUP.apRobot[<selected>]). The PLC pointer array is
 * dispatched to stable named instances because ADS does not expose the
 * members of a pointer element as a browsable HMI path. An element may override
 * the robot with data-robot-index (used by the overview cards).
 *
 *   data-jog-symbol="JOG.bJogXPlus"          hold-to-run jog button
 *   data-robot-bind="HMI_ROB._tcppos.x"      live read-only display
 *   data-robot-write="JOG.fLinearVelocity"   writable input (range/checkbox)
 *   data-robot-format="deg|mm|mode|bool|raw" display formatting
 *   data-robot-status="ok|warn|fault"        colour a boolean indicator
 *   data-robot-name                          fallback name when no PLC binding is present
 *   data-robot-selector                      <select> that sets the robot
 *   data-robot-index="2"                     pin an element to a fixed robot
 *
 * Skill hooks (resolved against SETUP.R1_PP / SETUP.R2_PP for the selected robot):
 *   data-skill-bind="HMI_BASE.eStatus"       live read (data-skill-format="state")
 *   data-skill-cmd="bExecute"                momentary command button (press TRUE / release FALSE)
 *   data-skill-index="2"                     pin a skill element to a fixed robot
 *
 * A suffix starting with "PLC1." is treated as an absolute symbol path.
 *
 * The HMI is NOT a safety device - it only sets/clears command bits.
 * Jog bits are never left latched: pointer capture guarantees release,
 * and focus/visibility loss or a robot switch clears every active jog.
 */
(function () {
    'use strict';

    var ROBOT_COUNT = 2;
    var selected = 1;
    var ROBOT_SYMBOLS = {
        1: 'SETUP.UR_ALPHA',
        2: 'SETUP.UR_BRAVO'
    };
    var SKILL_SYMBOLS = {
        1: 'SETUP.R1_PP',
        2: 'SETUP.R2_PP'
    };

    function base(index) {
        return 'ADS.PLC1.' + ROBOT_SYMBOLS[index] + '.';
    }

    function objectPath(suffix) {
        return suffix.replace(/\./g, '::');
    }

    function resolve(el, suffix) {
        if (!suffix) {
            return null;
        }
        if (suffix.indexOf('PLC1.') === 0) {
            return suffix;
        }
        var idxAttr = el.getAttribute('data-robot-index');
        var idx = idxAttr ? parseInt(idxAttr, 10) : selected;
        return base(idx) + objectPath(suffix);
    }

    function skillBase(index) {
        return 'ADS.PLC1.' + SKILL_SYMBOLS[index] + '.';
    }

    function skillResolve(el, suffix) {
        if (!suffix) {
            return null;
        }
        if (suffix.indexOf('PLC1.') === 0) {
            return suffix;
        }
        var idxAttr = el.getAttribute('data-skill-index');
        var idx = idxAttr ? parseInt(idxAttr, 10) : selected;
        return skillBase(idx) + objectPath(suffix);
    }

    function getFormat(el) {
        return el.getAttribute('data-robot-format') || el.getAttribute('data-skill-format') || 'raw';
    }

    var STATE_NAMES = {
        0: 'None', 1: 'Finalized', 2: 'Unconfigured', 3: 'ErrorProcessing',
        4: 'CleaningUp', 5: 'ShuttingDown', 6: 'Configuring', 7: 'Inactive',
        8: 'Deactivating', 9: 'Activating', 10: 'Active'
    };

    function stateInfo(value) {
        var name;
        if (typeof value === 'number') {
            name = STATE_NAMES[value] || String(value);
        } else {
            name = String(value);
            var dot = name.lastIndexOf('.');
            if (dot >= 0) { name = name.substring(dot + 1); }
        }
        switch (name) {
            case 'Active':          return { label: 'RUNNING', cls: 'status-ok' };
            case 'Inactive':        return { label: 'READY', cls: 'status-info' };
            case 'Configuring':
            case 'Activating':      return { label: 'STARTING', cls: 'status-warn' };
            case 'Deactivating':
            case 'CleaningUp':
            case 'ShuttingDown':    return { label: 'STOPPING', cls: 'status-warn' };
            case 'ErrorProcessing': return { label: 'ERROR', cls: 'status-fault' };
            case 'Unconfigured':
            case 'None':
            case 'Finalized':       return { label: 'IDLE', cls: 'status-idle' };
            default:                return { label: name.toUpperCase(), cls: 'status-idle' };
        }
    }

    function writeSymbol(path, value) {
        try {
            new TcHmi.Symbol('%s%' + path + '%/s%').write(value);
        } catch (err) {
            if (typeof TcHmi !== 'undefined' && TcHmi.Log) {
                TcHmi.Log.error('[RobotHmi] write failed ' + path + ': ' + err);
            }
        }
    }

    // ==============================================================
    // Momentary press (hold-to-run jog + skill/command buttons)
    //   data-jog-symbol  -> resolved against the robot base
    //   data-skill-cmd   -> resolved against the skill base
    // Press writes TRUE, release writes FALSE (never latched).
    // ==============================================================
    var activePress = {};

    function pressResolve(el) {
        if (el.getAttribute('data-jog-symbol')) {
            return resolve(el, el.getAttribute('data-jog-symbol'));
        }
        if (el.getAttribute('data-skill-cmd')) {
            return skillResolve(el, el.getAttribute('data-skill-cmd'));
        }
        return null;
    }

    function pressStart(el) {
        var path = pressResolve(el);
        if (!path || activePress[path]) {
            return;
        }
        activePress[path] = el;
        el.classList.add('jog-btn--active');
        writeSymbol(path, true);
    }

    function pressStop(el) {
        var path = pressResolve(el);
        if (!path) {
            return;
        }
        delete activePress[path];
        el.classList.remove('jog-btn--active');
        writeSymbol(path, false);
    }

    function stopAllPresses() {
        for (var path in activePress) {
            if (Object.prototype.hasOwnProperty.call(activePress, path)) {
                var el = activePress[path];
                if (el && el.classList) {
                    el.classList.remove('jog-btn--active');
                }
                writeSymbol(path, false);
            }
        }
        activePress = {};
    }

    function findPress(node) {
        while (node && node !== document) {
            if (node.getAttribute && (node.getAttribute('data-jog-symbol') || node.getAttribute('data-skill-cmd'))) {
                return node;
            }
            node = node.parentNode;
        }
        return null;
    }

    function onPointerDown(event) {
        var el = findPress(event.target);
        if (!el) {
            return;
        }
        if (el.setPointerCapture && event.pointerId !== undefined) {
            try { el.setPointerCapture(event.pointerId); } catch (e) { /* ignore */ }
        }
        pressStart(el);
    }

    function onPointerUp(event) {
        var el = findPress(event.target);
        if (el) {
            pressStop(el);
        }
    }

    // Delegated click for STOP / OPEN buttons (avoids inline handlers).
    function onClick(event) {
        var node = event.target;
        while (node && node !== document) {
            if (node.getAttribute) {
                if (node.hasAttribute && node.hasAttribute('data-robot-stop')) {
                    stopAllPresses();
                    return;
                }
                var open = node.getAttribute('data-robot-open');
                if (open) {
                    openRobot(open);
                    return;
                }
                var toggle = node.getAttribute('data-confirm-toggle');
                if (toggle) {
                    var dlg = document.getElementById(toggle);
                    if (dlg) {
                        dlg.classList.toggle('confirm-open');
                    }
                    return;
                }
            }
            node = node.parentNode;
        }
    }

    // ==============================================================
    // Read bindings
    // ==============================================================
    var readBindings = [];

    function formatValue(el, value) {
        if (value === undefined || value === null) {
            return '--';
        }
        switch (getFormat(el)) {
            case 'deg':   return (Number(value) * 180 / Math.PI).toFixed(2) + '\u00B0';
            case 'mm':    return (Number(value) * 1000).toFixed(1);
            case 'mode':  return Number(value) === 1 ? 'Automatic' : 'Manual';
            case 'bool':  return value ? 'Yes' : 'No';
            case 'state': return stateInfo(value).label;
            default:      return (typeof value === 'number') ? Number(value).toFixed(3) : String(value);
        }
    }

    function applyStatusColour(el, value) {
        if (getFormat(el) === 'state') {
            var info = stateInfo(value);
            el.classList.remove('status-ok', 'status-warn', 'status-fault', 'status-info', 'status-idle');
            el.classList.add(info.cls);
            return;
        }
        var kind = el.getAttribute('data-robot-status') || el.getAttribute('data-skill-status');
        if (!kind) {
            return;
        }
        el.classList.remove('status-ok', 'status-warn', 'status-fault', 'status-info', 'status-idle');
        var truthy = !!value;
        if (kind === 'ok') {
            el.classList.add(truthy ? 'status-ok' : 'status-warn');
        } else if (kind === 'fault') {
            el.classList.add(truthy ? 'status-fault' : 'status-ok');
        } else {
            el.classList.add(truthy ? 'status-warn' : 'status-ok');
        }
    }

    function setElementValue(el, value) {
        if (el.tagName === 'INPUT') {
            if (el.type === 'checkbox') {
                el.checked = !!value;
            } else if (document.activeElement !== el) {
                el.value = value;
            }
            return;
        }
        el.textContent = formatValue(el, value);
        applyStatusColour(el, value);
    }

    function bindRead(el) {
        var path = el.hasAttribute('data-skill-bind')
            ? skillResolve(el, el.getAttribute('data-skill-bind'))
            : resolve(el, el.getAttribute('data-robot-bind'));
        if (!path) {
            return;
        }
        var symbol = new TcHmi.Symbol('%s%' + path + '%/s%');
        var destroy = symbol.watch(function (data) {
            if (data.error === TcHmi.Errors.NONE) {
                setElementValue(el, data.value);
            }
        });
        readBindings.push({
            el: el,
            destroy: destroy,
            fixed: !!(el.getAttribute('data-robot-index') || el.getAttribute('data-skill-index'))
        });
    }

    function unbind(predicate) {
        readBindings = readBindings.filter(function (b) {
            if (predicate(b)) {
                try { b.destroy(); } catch (e) { /* ignore */ }
                return false;
            }
            return true;
        });
    }

    function rebindDynamicReads() {
        var els = [];
        unbind(function (b) {
            if (!b.fixed) {
                els.push(b.el);
                return true;
            }
            return false;
        });
        els.forEach(bindRead);
    }

    // ==============================================================
    // Write inputs
    // ==============================================================
    function initWriteElement(el) {
        if (el.__robotWriteInit) {
            return;
        }
        el.__robotWriteInit = true;
        el.addEventListener('input', function () {
            var path = el.hasAttribute('data-skill-write')
                ? skillResolve(el, el.getAttribute('data-skill-write'))
                : resolve(el, el.getAttribute('data-robot-write'));
            if (!path) {
                return;
            }
            var type = el.getAttribute('data-robot-type');
            var value;
            if (type === 'bool' || el.type === 'checkbox') {
                value = !!el.checked;
            } else if (type === 'string') {
                value = el.value;
            } else {
                value = parseFloat(el.value);
            }
            writeSymbol(path, value);
        });
    }

    // ==============================================================
    // Names / selection
    // ==============================================================
    function updateRecipeControls() {
        var recipeType = 'PickPlace';
        var allowedTypes = [recipeType];
        var recipeSelect = TcHmi.Controls.get('TcHmiRecipeSelect_1');
        var recipeEdit = TcHmi.Controls.get('TcHmiRecipeEdit_1');
        if (recipeSelect && typeof recipeSelect.setAllowedRecipeTypes === 'function') {
            recipeSelect.setAllowedRecipeTypes(allowedTypes);
        }
        if (recipeEdit) {
            if (typeof recipeEdit.setAllowedRecipeTypes === 'function') {
                recipeEdit.setAllowedRecipeTypes(allowedTypes);
            }
            if (typeof recipeEdit.setPreselectedRecipeType === 'function') {
                recipeEdit.setPreselectedRecipeType(recipeType);
            }
        }
    }

    function setSelectedRobot(index) {
        index = parseInt(index, 10);
        if (isNaN(index) || index < 1 || index > ROBOT_COUNT) {
            return;
        }
        stopAllPresses();
        selected = index;
        rebindDynamicReads();
        updateRecipeControls();
        var selectors = document.querySelectorAll('[data-robot-selector]');
        for (var i = 0; i < selectors.length; i++) {
            if (selectors[i].value !== String(index)) {
                selectors[i].value = String(index);
            }
        }
    }

    function navigateTo(content) {
        try {
            var region = TcHmi.Controls.get('Region_Center');
            if (region && typeof region.setTargetContent === 'function') {
                region.setTargetContent(content);
            }
        } catch (e) {
            if (typeof TcHmi !== 'undefined' && TcHmi.Log) {
                TcHmi.Log.error('[RobotHmi] navigate failed: ' + e);
            }
        }
    }

    function openRobot(index) {
        setSelectedRobot(index);
        navigateTo('Pages/RobotMove.content');
    }

    // ==============================================================
    // Scan / observe dynamically loaded content
    // ==============================================================
    function scan(root) {
        if (!root.querySelectorAll) {
            return;
        }
        var reads = root.querySelectorAll('[data-robot-bind]');
        for (var i = 0; i < reads.length; i++) {
            if (!reads[i].__robotBound) {
                reads[i].__robotBound = true;
                bindRead(reads[i]);
            }
        }
        var skillReads = root.querySelectorAll('[data-skill-bind]');
        for (var r = 0; r < skillReads.length; r++) {
            if (!skillReads[r].__robotBound) {
                skillReads[r].__robotBound = true;
                bindRead(skillReads[r]);
            }
        }
        var writes = root.querySelectorAll('[data-robot-write]');
        for (var j = 0; j < writes.length; j++) {
            initWriteElement(writes[j]);
        }
        var skillWrites = root.querySelectorAll('[data-skill-write]');
        for (var w = 0; w < skillWrites.length; w++) {
            initWriteElement(skillWrites[w]);
        }
        var selectors = root.querySelectorAll('[data-robot-selector]');
        for (var s = 0; s < selectors.length; s++) {
            if (!selectors[s].__robotSelInit) {
                selectors[s].__robotSelInit = true;
                selectors[s].addEventListener('change', function () {
                    setSelectedRobot(this.value);
                });
            }
            selectors[s].value = String(selected);
        }
        updateRecipeControls();
    }

    function removeBindingsIn(node) {
        if (!node.querySelectorAll) {
            return;
        }
        var removed = node.querySelectorAll('[data-robot-bind], [data-skill-bind]');
        if (!removed.length) {
            return;
        }
        unbind(function (b) {
            for (var i = 0; i < removed.length; i++) {
                if (removed[i] === b.el) {
                    return true;
                }
            }
            return false;
        });
    }

    function observe() {
        var observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                for (var i = 0; i < m.addedNodes.length; i++) {
                    var added = m.addedNodes[i];
                    if (added.nodeType === 1) {
                        if (added.getAttribute && (added.getAttribute('data-robot-bind') || added.getAttribute('data-skill-bind')) && !added.__robotBound) {
                            added.__robotBound = true;
                            bindRead(added);
                        }
                        scan(added);
                    }
                }
                for (var j = 0; j < m.removedNodes.length; j++) {
                    if (m.removedNodes[j].nodeType === 1) {
                        removeBindingsIn(m.removedNodes[j]);
                    }
                }
            });
        });
        observer.observe(document.body, { childList: true, subtree: true });
    }

    function attach() {
        document.addEventListener('pointerdown', onPointerDown, true);
        document.addEventListener('pointerup', onPointerUp, true);
        document.addEventListener('pointercancel', onPointerUp, true);
        document.addEventListener('lostpointercapture', onPointerUp, true);
        document.addEventListener('click', onClick, false);
        window.addEventListener('blur', stopAllPresses);
        document.addEventListener('visibilitychange', function () {
            if (document.hidden) {
                stopAllPresses();
            }
        });
        scan(document);
        observe();
    }

    window.RobotHmi = {
        stopAllJogs: stopAllPresses,
        setSelectedRobot: setSelectedRobot,
        openRobot: openRobot,
        getSelectedRobot: function () { return selected; }
    };

    if (typeof TcHmi !== 'undefined' && TcHmi.EventProvider) {
        TcHmi.EventProvider.register('onInitialized', function (e) {
            attach();
            return e;
        });
    } else {
        window.addEventListener('load', attach);
    }
})();
