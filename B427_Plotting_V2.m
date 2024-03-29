close all

%% TPDO data
figure Name 'Num Batteries'
hold on
plot(TPDO1.VB_numBatts(1,:), TPDO1.VB_numBatts(2,:))
plot(TPDO4.VB_NumBattFault(1,:), TPDO4.VB_NumBattFault(2,:))
plot(TPDO4.VB_NumBattActive(1,:), TPDO4.VB_NumBattActive(2,:))
hold off
title('Num Batteries')
legend('VB_numBatts', 'VB_NumBattFault', 'VB_NumBattActive')

figure Name 'SOC'
plot(TPDO1.VB_SOC(1,:), TPDO1.VB_SOC(2,:))
title('SOC')
legend('TPDO SOC')

figure Name 'Pack Voltage'
plot(TPDO2.VB_Pack_Voltage(1,:), TPDO2.VB_Pack_Voltage(2,:))
title('Pack Voltage')
legend('Pacl Votlage')

figure Name 'Temperature'
plot(TPDO3.VB_Temperature(1,:), TPDO3.VB_Temperature(2,:))
title('Temperature')
legend('Temperature')

figure Name 'Currents'
hold on
plot(TPDO2.VB_Current(1,:), TPDO2.VB_Current(2,:))
plot(TPDO3.InstantMaxChargeCurrent(1,:), TPDO3.InstantMaxChargeCurrent(2,:))
plot(TPDO5.Regen_Current_Limit(1,:), TPDO5.Regen_Current_Limit(2,:) )
hold off
title('Currents')
legend('VB_Current', 'InstantMaxChargeCurrent', 'Regen_Current_Limit')

figure Name 'Faults'
hold on
plot(TPDO4.VB_Charge_Fault(1,:), TPDO4.VB_Charge_Fault(2,:))
plot(TPDO4.VB_Discharge_Fault(1,:), TPDO4.VB_Discharge_Fault(2,:))
hold off
title('Faults')
legend('VB_Charge_Fault', 'VB_Discharge_Fault')

figure Name 'Cell Voltages'
hold on
plot(TPDO5.Min_Cell_Voltage(1,:), TPDO5.Min_Cell_Voltage(2,:))
plot(TPDO5.Max_Cell_Voltage(1,:), TPDO5.Max_Cell_Voltage(2,:))
hold off
title('Cell Voltages')
legend('Min Cell', 'Max Cell')


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
ylim([3000, 3600])
title('Cell Voltages')
ylabel('Cell Voltages (mV)')
xlabel('Time (h)')
% legend('Battery 1', 'Battery 2', 'Battery 3', 'Battery 4', 'Battery 5', 'Battery 6','Battery 7', 'Battery 8', 'Battery 9', 'Battery 10', 'Battery 11', 'Battery 12')
hold off

%% SDO data

figure Name 'Max Cell Voltages'
hold on
for k = 1:12
    plot(battery(k).maxCellVoltage(1,:), battery(k).maxCellVoltage(2,:))
end
ylim([2500, 3000])
title('Max Cell Voltages')
ylabel('Cell Voltages (mV)')
xlabel('Time (h)')
legend('Battery 1', 'Battery 2', 'Battery 3', 'Battery 4', 'Battery 5', 'Battery 6','Battery 7', 'Battery 8', 'Battery 9', 'Battery 10', 'Battery 11', 'Battery 12')
hold off

%% SDO data

figure Name 'Min Cell Voltages'
hold on
for k = 1:12
    plot(battery(k).minCellVoltage(1,:), battery(k).minCellVoltage(2,:))
end
ylim([2500, 3600])
title('Min Cell Voltages')
ylabel('Cell Voltages (mV)')
xlabel('Time (h)')
legend('Battery 1', 'Battery 2', 'Battery 3', 'Battery 4', 'Battery 5', 'Battery 6','Battery 7', 'Battery 8', 'Battery 9', 'Battery 10', 'Battery 11', 'Battery 12')
hold off

%% SDO data

figure Name 'Cumulative Charge'
hold on
for k = 1:12
    plot(battery(k).cumChargeAh(1,:), battery(k).cumChargeAh(2,:))
end
title('Cumulative Charge')
ylabel('Cumulative Charge (Ah)')
xlabel('Time (h)')
hold off

figure Name 'Cumulative Discharge'
hold on
maxCumDischAhVal = 0;
minCumDischAhVal = battery(1).cumDischAh(2,1);
for k = 1:12
    plot(battery(k).cumDischAh(1,:), battery(k).cumDischAh(2,:))
    
    for j = 1:battery(k).cumDischAhindex
        if battery(k).cumDischAh(2,j) < minCumDischAhVal
            minCumDischAhVal = battery(k).cumDischAh(2,j);
        elseif battery(k).cumDischAh(2,j) > maxCumDischAhVal
            maxCumDischAhVal = battery(k).cumDischAh(2,j);
        end
    end

end
% ylim([1000, 3000])
title('Cumulative Discharge')
ylabel('Cumulative Discharge (Ah)')
xlabel('Time (h)')
hold off