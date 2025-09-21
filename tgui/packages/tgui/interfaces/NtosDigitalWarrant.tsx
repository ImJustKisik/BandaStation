import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Button, Input, LabeledList, Section, Stack } from 'tgui-core/components';

type Warrant = {
  id: string;
  namewarrant: string;
  jobwarrant: string;
  charges: string;
  auth: string;
  idauth: string;
  arrestsearch: string;
};

type CrewMember = {
  name: string;
  rank: string;
};

type Data = {
  warrants?: Warrant[];
  active?: Warrant;
  crew_manifest?: CrewMember[];
};

export const NtosDigitalWarrant = () => {
  const { act, data } = useBackend<Data>();
  const { warrants = [], active, crew_manifest = [] } = data;

  return (
    <Window width={500} height={600}>
      <Window.Content>
        {active ? (
          <WarrantEditor
            warrant={active}
            act={act}
            crew_manifest={crew_manifest}
          />
        ) : (
          <WarrantList warrants={warrants} act={act} />
        )}
      </Window.Content>
    </Window>
  );
};

type WarrantEditorProps = {
  warrant: Warrant;
  act: (action: string, params?: object) => void;
  crew_manifest: CrewMember[];
};

const WarrantEditor = (props: WarrantEditorProps) => {
  const { warrant, act, crew_manifest } = props;
  return (
    <Section title={warrant.namewarrant}>
      <LabeledList>
        <LabeledList.Item label="Name">
          <Input
            value={warrant.namewarrant}
            onChange={value => act('edit_name', { name: value, job: warrant.jobwarrant })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Job">
          <Input
            value={warrant.jobwarrant}
            onChange={value => act('edit_name', { name: warrant.namewarrant, job: value })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Charges">
          <Input
            value={warrant.charges}
            onChange={value => act('edit_charges', { charges: value })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Authorized">
          {warrant.auth}
          <Button ml={1} onClick={() => act('authorize')}>
            Auth
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Access Auth">
          {warrant.idauth}
          <Button ml={1} onClick={() => act('authorize_access')}>
            Auth Access
          </Button>
        </LabeledList.Item>
      </LabeledList>
      <CrewManifestList crew={crew_manifest} act={act} />
      <Stack mt={2} justify="space-between">
        <Button onClick={() => act('save')}>Save</Button>
        <Button onClick={() => act('delete', { id: warrant.id })}>Delete</Button>
        <Button onClick={() => act('back')}>Back</Button>
      </Stack>
    </Section>
  );
};

type CrewManifestListProps = {
  crew: CrewMember[];
  act: (action: string, params?: object) => void;
};

const CrewManifestList = (props: CrewManifestListProps) => {
  const { crew, act } = props;
  if (!crew?.length) {
    return null;
  }
  return (
    <Section title="Crew Manifest">
      <Stack wrap>
        {crew.map(c => (
          <Button
            key={c.name + c.rank}
            onClick={() => act('select_from_manifest', { name: c.name, rank: c.rank })}
            mr={1}
            mb={1}
          >
            {c.name} ({c.rank})
          </Button>
        ))}
      </Stack>
    </Section>
  );
};


type WarrantListProps = {
  warrants: Warrant[];
  act: (action: string, params?: object) => void;
};

const WarrantList = (props: WarrantListProps) => {
  const { warrants, act } = props;
  return (
    <Section
      title="Warrants"
      buttons={
        <>
          <Button onClick={() => act('add_arrest')}>Add Arrest</Button>
          <Button onClick={() => act('add_search')}>Add Search</Button>
        </>
      }
    >
      {warrants.length ? (
        warrants.map((warrant) => (
          <Stack key={warrant.id} justify="space-between" mb={1}>
            <Stack.Item grow>
              {warrant.namewarrant}: {warrant.charges}
            </Stack.Item>
            <Button onClick={() => act('open', { id: warrant.id })}>View</Button>
            <Button onClick={() => act('delete', { id: warrant.id })}>Delete</Button>
          </Stack>
        ))
      ) : (
        'No warrants.'
      )}
    </Section>
  );
};

