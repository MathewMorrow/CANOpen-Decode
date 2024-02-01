close all

%% TPDO data
figure'
hold on
plot(TPDO1.VB_numBatts(1,:), TPDO1.VB_numBatts(2,:))
plot(TPDO4.VB_NumBattFault(1,:), TPDO4.VB_NumBattFault(2,:))
plot(TPDO4.VB_NumBattActive(1,:), TPDO4.VB_NumBattActive(2,:))
hold off
legend('VB_numBatts', 'VB_NumBattFault', 'VB_NumBattActive')

figure
plot(TPDO1.VB_SOC(1,:), TPDO1.VB_SOC(2,:))

figure
plot(TPDO2.VB_Pack_Voltage(1,:), TPDO2.VB_Pack_Voltage(2,:))

figure
plot(TPDO3.VB_Temperature(1,:), TPDO3.VB_Temperature(2,:))

figure
hold on
plot(TPDO2.VB_Current(1,:), TPDO2.VB_Current(2,:))
plot(TPDO3.InstantMaxChargeCurrent(1,:), TPDO3.InstantMaxChargeCurrent(2,:))
plot(TPDO5.Regen_Current_Limit(1,:), TPDO5.Regen_Current_Limit(2,:) )
hold off
legend('VB_Current', 'InstantMaxChargeCurrent', 'Regen_Current_Limit')

figure
hold on
plot(TPDO4.VB_Charge_Fault(1,:), TPDO4.VB_Charge_Fault(2,:))
plot(TPDO4.VB_Discharge_Fault(1,:), TPDO4.VB_Discharge_Fault(2,:))
hold off
legend('VB_Charge_Fault', 'VB_Discharge_Fault')

figure
hold on
plot(TPDO5.Min_Cell_Voltage(1,:), TPDO5.Min_Cell_Voltage(2,:))
plot(TPDO5.Max_Cell_Voltage(1,:), TPDO5.Max_Cell_Voltage(2,:))
hold off


%% SDO data

figure Name 'Current'
for k = 1:12
    plot(battery(k).Current(1,:), battery(k).Current(2,:))
    hold on
end
title('Current')
ylabel('Current (A)')
xlabel('Time (h)')
legend('Battery 1', 'Battery 2', 'Battery 3', 'Battery 4', 'Battery 5', 'Battery 6','Battery 7', 'Battery 8', 'Battery 9', 'Battery 10', 'Battery 11', 'Battery 12')
hold off

%% SDO data

figure Name 'Cell Voltages'
hold on
for k = 1:12
    plot(battery(k).minCellVoltage(1,:), battery(k).minCellVoltage(2,:))
    plot(battery(k).maxCellVoltage(1,:), battery(k).maxCellVoltage(2,:))
end
ylim([3200, 3400])
title('Cell Voltages')
ylabel('Cell Voltages (mV)')
xlabel('Time (h)')
% legend('Battery 1', 'Battery 2', 'Battery 3', 'Battery 4', 'Battery 5', 'Battery 6','Battery 7', 'Battery 8', 'Battery 9', 'Battery 10', 'Battery 11', 'Battery 12')
hold off