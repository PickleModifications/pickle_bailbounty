import { Button, Flex, Group, ScrollArea, useMantineTheme } from "@mantine/core";
import { TableScrollArea } from "../tablescrollarea/TableScrollArea";
import { useLocale } from "../../providers/locale/Locale";
import { Currency } from "../../providers/currency/Currency";
import { useState } from "react";
import { useBountyApp } from "../../providers/bounty/Bounty";
import { useNuiEvent } from "../../providers/nui/useNui";
import { useConfig } from "../../providers/config/Config";
import { MenuModal } from "../menumodal/MenuModal";
import { fetchNui } from "../../providers/nui/fetchNui";
import { Datetime } from "../datetime/Datetime";

export type Bail = {
    identifier: string;
    description?: string;
    image?: string;
    name: string;
    startdate: number;
    completiondate: number;
    lastcompliance?: number;
    status: string;
}

export function Pill({c, children, style} : {c: string, children: any, style?: any}) {
    const theme = useMantineTheme();
    return <div style={{ color: "white", backgroundColor: theme.colors[c][9], textAlign: "center", paddingLeft: 10, paddingRight: 10, borderRadius: 5, width: "fit-content",  ...style}}>{children}</div>
}

function BailRegistry() {
    const theme = useMantineTheme();
    const translate = useLocale();
    const {config} = useConfig();
    const {bountyApp, setBountyApp} = useBountyApp();
    const [bailRegistry, setBailRegistry] = useState<Bail[]>(bountyApp.bailRegistry);
    const [viewingBail, setViewingBail] = useState(false);
    const [viewBail, setViewBail] = useState<Bail | null>(null);
    useNuiEvent("updateBailRegistry", function(data) {
        setBailRegistry(data.bailRegistry);
    });
    return (
        <Flex p={10} flex={1} w={"100%"} h={"100%"} pos={"relative"} style={{borderBottomLeftRadius: 5, borderBottomRightRadius: 5, backgroundColor: "transparent"}}>
            <TableScrollArea defaultSort={{column: 4, descending: true}} data={{
                caption: translate("header_bail"),
                head: ["", translate("bail_registry_name"), translate("bail_registry_startdate"), translate("bail_registry_lastcompliance"), translate("bail_registry_status"), ''],
                body: bailRegistry.map((bail, bailIndex) => [
                    <img src={bail.image || config.defaultPlayerImage} alt={bail.name} width={6 * 6} height={8 * 6}/>,
                    bail.name,
                    Datetime(bail.startdate, config.currency.locale),
                    // Datetime(bail.completiondate, config.currency.locale), 
                    (bail.lastcompliance ? Datetime(bail.lastcompliance, config.currency.locale) : translate("bail_registry_never")),
                    (bail.status == "compliant" ? translate("bail_registry_status_compliant") : translate("bail_registry_status_noncompliant")),
                    <Button size="xs" color={"dark.7"} onClick={() => {
                        setViewBail(bail);
                        setViewingBail(true);
                    }}>Manage Bail</Button>
                ])
            }}/>
            <MenuModal title={translate("view_bail")} close={() => {
                setViewingBail(false);
                setTimeout(() => {
                    setViewBail(null);
                }, 200);
            }} visible={viewingBail}>
                {viewBail && (
                    <Flex gap={10} pl={10} pr={10} direction={"column"}>
                        <Flex align={"center"} gap={10}>
                            <img width={6 * 15} height={8 * 15} src={viewBail.image || config.defaultPlayerImage}></img>
                            <Flex gap={0} direction={"column"}>
                                <Flex gap={10}>
                                    <b>{translate("bail_registry_name")}:</b>
                                    {viewBail.name}
                                </Flex>
                                <Flex gap={10}>
                                    <b>{translate("bail_registry_startdate")}:</b>
                                    {Datetime(viewBail.startdate, config.currency.locale)}
                                </Flex>
                                <Flex gap={10}>
                                    <b>{translate("bail_registry_completiondate")}:</b>
                                    {Datetime(viewBail.completiondate, config.currency.locale)}
                                </Flex>
                                <Flex gap={10}>
                                    <b>{translate("bail_registry_lastcompliance")}:</b>
                                    {(viewBail.lastcompliance ? Datetime(viewBail.lastcompliance, config.currency.locale) : translate("bail_registry_never"))}
                                </Flex>
                                <Flex gap={10}>
                                    <Pill c={(viewBail.status == "compliant" ? "green" : "red")}>{(viewBail.status == "compliant" ? translate("bail_registry_status_compliant") : translate("bail_registry_status_noncompliant"))}</Pill>
                                </Flex>
                            </Flex>
                        </Flex>
                        <ScrollArea style={{ height: 75, color: theme.colors.dark[1]}}>
                            {viewBail.description || "No description available."}
                        </ScrollArea>
                        {config.permissions.bailManage && (
                        <>
                            <Button color={"green"} onClick={() => {
                                fetchNui("clearBail", { bounty: viewBail }).then(() => {
                                    setViewingBail(false);
                                });
                            }}>{translate("view_bail_clear")}</Button>
                            <Button color={"red"} onClick={() => {
                                fetchNui("revokeBail", { bounty: viewBail }).then(() => {
                                    setViewingBail(false);
                                });
                            }
                            }>{translate("view_bail_revoke")}</Button>
                        </>
                        )}
                    </Flex>
                )}
            </MenuModal>
        </Flex>
    )
}

export default BailRegistry;