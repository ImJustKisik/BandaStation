import { useBackend, useLocalState } from '../backend';
import { Button, LabeledList, Section, NumberInput } from '../components';
import { Window } from '../layouts';

export const FissionControl = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    status,
    temperature,
    reactivity,
    power_output,
    control_rods = [],
  } = data;

  return (
    <Window>
      <Window.Content>
        <Section title="Reactor Status">
          <LabeledList>
            <LabeledList.Item label="Status">
              {status}
            </LabeledList.Item>
            <LabeledList.Item label="Core Temperature">
              {temperature ? `${temperature.toFixed(2)} K` : 'N/A'}
            </LabeledList.Item>
            <LabeledList.Item label="Reactivity Level">
              {reactivity ? reactivity.toFixed(2) : 'N/A'}
            </LabeledList.Item>
            <LabeledList.Item label="Power Output">
              {power_output ? `${(power_output / 1000).toFixed(2)} kW` : 'N/A'}
            </LabeledList.Item>
          </LabeledList>
          <Button
            icon={status === 'Reactor Online' ? 'power-off' : 'power-off'}
            content={status === 'Reactor Online' ? 'Deactivate' : 'Activate'}
            color={status === 'Reactor Online' ? 'danger' : 'good'}
            onClick={() => act('toggle_power')}
          />
          <Button
            icon="exclamation-triangle"
            content="SCRAM"
            color="danger"
            onClick={() => act('scram')}
            ml={2}
          />
        </Section>
        <Section title="Control Rods">
          {control_rods.length === 0 && (
            <p>No control rods detected.</p>
          )}
          {control_rods.map((rod, index) => (
            <LabeledList.Item key={rod.ref} label={`Rod ${index + 1}`}>
              <NumberInput
                value={rod.insertion}
                minValue={0}
                maxValue={100}
                step={1}
                unit="%"
                width="60px"
                onChange={(e, value) => act('set_rod_insertion', {
                  ref: rod.ref,
                  value: value,
                })}
              />
            </LabeledList.Item>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
