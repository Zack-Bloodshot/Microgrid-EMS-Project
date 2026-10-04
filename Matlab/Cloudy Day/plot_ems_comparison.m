function plot_ems_comparison(sunny, cloudy, phase_name, model_name)
%PLOT_EMS_COMPARISON Plot load, dispatch, SOC, and curtailment by EMS model.

    sunny_phase = sunny.(phase_name);
    cloudy_phase = cloudy.(phase_name);
    time = sunny.time;
    row_count = 4;

    figure('Name', [model_name, ' - Sunny vs Cloudy'], ...
        'Position', [100, 100, 1250, 900]);
    plot_profile_pair(sunny, cloudy, time, row_count, 1);
    plot_dispatch_pair(sunny_phase, cloudy_phase, time, row_count, 2);
    plot_soc_pair(sunny_phase, cloudy_phase, time, row_count, 3);
    plot_curtailment_pair(sunny_phase, cloudy_phase, time, row_count, 4);
    sgtitle([model_name, ': Sunny vs Cloudy']);
end

function plot_profile_pair(sunny, cloudy, time, row_count, row)
    subplot(row_count, 2, 2 * row - 1);
    plot(time, sunny.P_pv, 'LineWidth', 1.4); hold on;
    plot(time, sunny.P_load, 'LineWidth', 1.4);
    grid on; xlim([0 24]);
    ylabel('Power [kW]'); title('Sunny: PV and Load');
    legend('P_{pv}', 'P_{load}', 'Location', 'northwest');

    subplot(row_count, 2, 2 * row);
    plot(time, cloudy.P_pv, 'LineWidth', 1.4); hold on;
    plot(time, cloudy.P_load, 'LineWidth', 1.4);
    grid on; xlim([0 24]);
    ylabel('Power [kW]'); title('Cloudy: PV and Load');
    legend('P_{pv}', 'P_{load}', 'Location', 'northwest');
end

function plot_dispatch_pair(sunny_phase, cloudy_phase, time, row_count, row)
    subplot(row_count, 2, 2 * row - 1);
    plot_dispatch(sunny_phase, time, 'Sunny: Dispatch');
    subplot(row_count, 2, 2 * row);
    plot_dispatch(cloudy_phase, time, 'Cloudy: Dispatch');
end

function plot_dispatch(phase, time, plot_title)
    plot(time, phase.P_ch, 'LineWidth', 1.2); hold on;
    plot(time, -phase.P_dis, 'LineWidth', 1.2);
    plot(time, phase.P_gimp, 'LineWidth', 1.2);
    plot(time, -phase.P_gexp, 'LineWidth', 1.2);
    yline(0, 'k-'); grid on; xlim([0 24]);
    ylabel('Power [kW]'); title(plot_title);
    legend('P_{ch}', '-P_{dis}', 'P_{grid,imp}', '-P_{grid,exp}', ...
        'Location', 'northwest');
end

function plot_soc_pair(sunny_phase, cloudy_phase, time, row_count, row)
    subplot(row_count, 2, 2 * row - 1);
    plot([time, time(end) + 0.25], sunny_phase.SOC, 'LineWidth', 1.4);
    grid on; xlim([0 24]); ylim([0 1]);
    ylabel('SOC [-]'); title('Sunny: Battery SOC');

    subplot(row_count, 2, 2 * row);
    plot([time, time(end) + 0.25], cloudy_phase.SOC, 'LineWidth', 1.4);
    grid on; xlim([0 24]); ylim([0 1]);
    ylabel('SOC [-]'); title('Cloudy: Battery SOC');
end

function plot_curtailment_pair(sunny_phase, cloudy_phase, time, row_count, row)
    subplot(row_count, 2, 2 * row - 1);
    area(time, sunny_phase.P_curt, 'FaceAlpha', 0.5);
    grid on; xlim([0 24]); ylabel('Power [kW]');
    title('Sunny: PV Curtailment');

    subplot(row_count, 2, 2 * row);
    area(time, cloudy_phase.P_curt, 'FaceAlpha', 0.5);
    grid on; xlim([0 24]); ylabel('Power [kW]');
    title('Cloudy: PV Curtailment');
end
