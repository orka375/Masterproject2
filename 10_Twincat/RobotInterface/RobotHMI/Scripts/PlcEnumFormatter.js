(function () {
    'use strict';

    var values = {
        'E_CommandHandshakeState': ['Idle', 'WaitAck', 'WaitResult', 'Done'],
        'E_PointStoreResult': ['POINTSTORE_IDLE', 'POINTSTORE_BUSY', 'POINTSTORE_DONE', 'POINTSTORE_CONFIGURATION_ERROR', 'POINTSTORE_DATABASE_ERROR'],
        'eBA': ['MoveL', 'MoveJ', 'MoveLRelativ', 'MoveJRelativ', 'SetDO', 'ReadDI', 'MoveJJoints', 'NavigateToGoal', 'NavigateToPoint', 'Dock', 'Undock', 'Home'],
        'eHealth': ['Unkown', 'Dead', 'Offline', 'Sick', 'Healty'],
        'eMessageCategories': ['None', 'TimeoutFailure', 'MissingData', 'LostConnection', 'Undefined', 'NotImplemented', 'NotAllowed', 'ParentFailed', 'External', 'Positiv', 'StateMachine', 'HardwareFailure'],
        'eMode': ['Manual', 'Automatic'],
        'eProgress': ['INIT', 'ACKNOWLEDGE', 'RUNNING', 'FINALIZED', 'ABORTED'],
        'eResult': ['NONE', 'SUCCESS', 'FAILURE', 'ERROR'],
        'eSeverity': ['Info', 'Warning', 'Error', 'Critical'],
        'eState': ['None', 'Finalized', 'Unconfigured', 'ErrorProcessing', 'CleaningUp', 'ShuttingDown', 'Configuring', 'Inactive', 'Deactivating', 'Activating', 'Active']
    };

    function format(type, value) {
        var index = Number(value);
        var labels = values[type];
        return labels && index >= 0 && index < labels.length ? labels[index] : 'Unknown (' + value + ')';
    }

    function bind(controlId, symbolExpression, type) {
        var control = TcHmi.Controls.get(controlId);
        if (!control) {
            return null;
        }
        return new TcHmi.Symbol(symbolExpression).watch(function (data) {
            if (data && data.error === TcHmi.Errors.NONE) {
                control.setText(format(type, data.value));
            }
        });
    }

    window.PlcEnumFormatter = {
        bind: bind,
        format: format,
        values: values
    };
})();