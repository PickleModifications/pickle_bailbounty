import { ReactNode, createContext, useContext, useState } from 'react'
import '@mantine/core/styles.css';
import { CloseButton, Flex, MantineProvider, useMantineTheme } from '@mantine/core'
import { ConfigProvider } from './providers/config/Config';
import { useLocale } from './providers/locale/Locale';
import { BountyAppProvider, useBountyApp } from './providers/bounty/Bounty';
import BountyPage from './components/bountypage/BountyPage';
import BailRegistry from './components/bailregistry/BailRegistry';
import CurrentBounty from './components/currentbounty/CurrentBounty';
import { useNuiEvent } from './providers/nui/useNui';
import { fetchNui } from './providers/nui/fetchNui';

type AppSection = {
  name: string;
  label: string;
}

function BountyContent({section} : {section: string}) {
  const theme = useMantineTheme()
  if (section == "bounty") {
    return <BountyPage/>
  }
  else if (section == "bail") {
    return <BailRegistry/>
  }
  else if (section == "current_bounty") {
    return <CurrentBounty/>
  }
  return (
    <Flex flex={1} w={"100%"} h={"100%"} style={{borderBottomLeftRadius: 5, borderBottomRightRadius: 5, backgroundColor: theme.colors.dark[8]}}>
      ERROR. NO CONTENT.
    </Flex>
  );
}

function BountyApp() {
  const [show, setShow] = useState(false)
  const [showDisplay, setShowDisplay] = useState(false)
  const theme = useMantineTheme()
  const [sections, setSections] = useState<AppSection[]>([]);
  const setAppDisplay = function(bool: boolean) {
    if (bool) {
      setShowDisplay(true)
      setTimeout(() => {
        setShow(true)
      }, 10)
    }
    else {
      setShow(false)
      setTimeout(() => {
        setShowDisplay(false)
      }, 200)
    }
  }
  const [selectedSection, setSelectedSection] = useState((sections.length > 0) ? sections[0].name : null)
  useNuiEvent("setAppDisplay", function(data) {
    setAppDisplay(data.data)
  })
  useNuiEvent("setSections", function(data) {
    let newSections = data.sections;
    let sectionIndex = -1;
    if (selectedSection != null) {
      for (let i = 0; i < newSections.length; i++) {
        if (newSections[i].name == selectedSection) {
          sectionIndex = i;
          break;
        }
      }
    }
    if (sectionIndex > 0) {
      if (selectedSection != newSections[sectionIndex].name) {
        setSelectedSection(newSections[sectionIndex].name)
      }
    }
    else {
      setSelectedSection((newSections.length > 0) ? newSections[0].name : null)
    }
    setSections(newSections)
  })
  if (sections.length < 1) {
    if (showDisplay) {
      fetchNui("closeApp", {noAccess: true})
    }
  }
  return (
    <div style={{position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -50%)", transition: "opacity 0.2s", opacity: (show ? 1.0 : 0.0), display: (showDisplay ? "flex" : "none") }}>
      {(showDisplay && selectedSection) &&
        <Flex w={900} h={550} pos={"relative"} direction={"column"} style={{backgroundImage: 'url("images/background.png")', backgroundSize: "100%", borderRadius: 5}}>
          <Flex align={"center"}  w={"100%"} style={{borderTopLeftRadius: 5, borderTopRightRadius: 5}}>
            <Flex flex={1} align={"center"} justify={"center"} gap={10} p={10}>
              {sections.map((section, index) => {
                return (
                  <Flex justify={"center"} flex={1} key={index} onClick={() => {
                    if (section.name != selectedSection) {
                      setSelectedSection(section.name)
                    }
                  }} style={{cursor: "pointer", userSelect:"none", transition: "background-color 0.2s", borderRadius: 5, padding: 5, paddingLeft: 10, paddingRight: 10, backgroundColor: (selectedSection == section.name ? "rgba(255, 255, 255, 0.1)" : undefined)}}>
                    {section.label}
                  </Flex>
                )
              })}
            </Flex>
            <CloseButton mr={10} size={30} onClick={() => {
              fetchNui("closeApp", {})
            }}/>
          </Flex>
          <div style={{position: "relative", height: 495}}>
            <BountyContent section={selectedSection}/>
          </div>
        </Flex>
      }
    </div>
  )
}

function App() {
  return (
    <MantineProvider defaultColorScheme='dark' theme={{
      colors: {
      dark: ["rgba(201, 201, 201, 1)", "rgba(184, 184, 184, 1)", "rgba(130, 130, 130, 1)", "rgba(105, 105, 105, 0.9)", "rgba(66, 66, 66, 0.9)", "rgba(26, 26, 26, 0.65)", "rgba(18, 18, 18, 0.65)", "rgba(18, 18, 18, 0.9)", "rgba(0, 0, 0, 0.9)", "rgba(0, 0, 0, 0.9)"],
      },
    }}>
      <ConfigProvider>
      <BountyAppProvider>
      <BountyApp/>
      </BountyAppProvider>
      </ConfigProvider>
    </MantineProvider>
  )
}

export default App