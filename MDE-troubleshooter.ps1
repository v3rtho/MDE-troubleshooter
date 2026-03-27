# Author: Thomas Verheyden
# New release: 27.03.2025
# Version: 3.1.0
# Blogpost: https://vertho.tech/2023/06/30/tool-mde-troubleshooter-is-born/
# Website: vertho.tech
# Twitter: @thomasvrhydn
# Disclaimer: Script provided as is. Use at own risk. No guarantees or warranty provided.

<#
README:
This tool is designed to assist you in analyzing issues related to Defender for Endpoint on your local endpoint.
It offers a centralized view of the security configuration, log files, updates, and provides access to the Performance Analyzer.
#>

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')  
[xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="MDE Troubleshooter v3.0" Height="700" Width="1000" WindowStyle="ToolWindow" ResizeMode="NoResize" Background="#F5F5F5">
    
    <Window.Resources>
        <Style x:Key="MenuButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Height" Value="45"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="20,0,10,0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#3A3A5A"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="MenuButtonActive" TargetType="Button" BasedOn="{StaticResource MenuButton}">
            <Setter Property="Background" Value="#1E1E2E"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style x:Key="HeaderLabel" TargetType="Label">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,5,0,0"/>
        </Style>
        <Style x:Key="ValueLabel" TargetType="Label">
            <Setter Property="FontStyle" Value="Italic"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,5,0,0"/>
        </Style>
        <Style x:Key="ActionButton" TargetType="Button">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Background" Value="#E0E0E0"/>
            <Setter Property="BorderBrush" Value="#333"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style x:Key="SectionBorder" TargetType="Border">
            <Setter Property="BorderBrush" Value="#CCC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="5"/>
            <Setter Property="Padding" Value="15"/>
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Background" Value="White"/>
        </Style>
    </Window.Resources>
    
    <Grid Name="MainWindow1">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="200"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- Left Side Menu -->
        <Border Grid.Column="0" Background="#2D2D44">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Border Grid.Row="0" Background="#1E1E2E" Padding="15,20">
                    <StackPanel>
                        <TextBlock Text="MDE" FontSize="24" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                        <TextBlock Text="Troubleshooter" FontSize="14" Foreground="White" FontFamily="Segoe UI"/>
                        <TextBlock Text="Made by Thomas Verheyden" FontSize="10" Foreground="#888" FontFamily="Segoe UI" Margin="0,10,0,0"/>
                    </StackPanel>
                </Border>
                <StackPanel Grid.Row="1" Margin="0,10,0,0">
                    <Button Name="btnMenuDefenderAV" Content="&#x1F6E1;  Defender AV" Style="{StaticResource MenuButtonActive}"/>
                    <Button Name="btnMenuASR" Content="&#x1F6A8;  Attack Surface" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuExclusions" Content="&#x1F4DD;  Exclusions" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuUpdates" Content="&#x1F504;  Updates" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuLogs" Content="&#x1F4CB;  Logs" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuPerformance" Content="&#x1F4CA;  Performance" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuProxy" Content="&#x1F310;  Proxy" Style="{StaticResource MenuButton}"/>
                    <Button Name="btnMenuFirewall" Content="&#x1F525;  Firewall" Style="{StaticResource MenuButton}"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Main Content Area -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <!-- Header -->
            <Border Grid.Row="0" Background="#2D2D44" Padding="15,10">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0">
                        <Label Name="lblComputerName" Content="ComputerName" FontSize="18" FontWeight="Bold" FontFamily="Segoe UI" Foreground="White"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <Label Content="OrgID:" FontWeight="Bold" FontFamily="Segoe UI" Foreground="White" FontSize="11"/>
                        <Label Name="lblOrgID_txt" Content="N/A" FontStyle="Italic" FontFamily="Segoe UI" Foreground="White" FontSize="11"/>
                    </StackPanel>
                </Grid>
            </Border>
            
            <!-- Content Panels -->
            <Grid Grid.Row="1">
                
                <!-- Panel 1: Defender AV -->
                <ScrollViewer Name="panelDefenderAV" VerticalScrollBarVisibility="Auto" Visibility="Visible">
                    <Grid Margin="10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <!-- Version Information -->
                        <Border Grid.Column="0" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Version Information" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="AM Engine Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblAMEngineVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="AM Product Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblAMProductVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="AM Service Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblAMServiceVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="NIS Engine Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblNISEngineVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="AM Running Mode:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblAMRunningMode_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="Computer State:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblComputerState_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- Service Status -->
                        <Border Grid.Column="1" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Service Status" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="170"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="AM Service Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblAMServiceEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Antivirus Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblAntivirusEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Antispyware Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblAntispywareEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="NIS Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblNISEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="Is Virtual Machine:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblIsVirtualMachine_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="Computer ID:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblComputerID_txt" Content="N/A" Style="{StaticResource ValueLabel}" FontSize="10"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- Real-Time Protection -->
                        <Border Grid.Column="0" Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Real-Time Protection" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="180"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="RealTime Protection:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblRealTimeProtection_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="OnAccess Protection:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblOnAccessProtection_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Behavior Monitor:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblBehaviorMonitor_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="IOAV Protection:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblIoavProtection_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="Tamper Protection:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblTamper_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="Tamper Source:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblTamperSource_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- Scan Information -->
                        <Border Grid.Column="1" Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Scan Information" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Full Scan Age:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblFullScanAge_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Full Scan Start:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblFullScanStartTime_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Full Scan End:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblFullScanEndTime_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="Quick Scan Age:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblQuickScanAge_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="Quick Scan Start:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblQuickScanStartTime_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="Quick Scan End:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblQuickScanEndTime_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- Protection Settings -->
                        <Border Grid.Column="0" Grid.Row="2" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Protection Settings" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="170"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Cloud Block Level:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblCloudBlockLevel_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Block at First sight:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblPUAProtect_text" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Cloud Timeout:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblCloudTimeout_text" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="Quarantine Days:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblQuarantine_text" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="File Hash Computation:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblEnableFileHashComputation_Text" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="Device Control:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblDeviceControl_Text" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <!-- Additional Info -->
                        <Border Grid.Column="1" Grid.Row="2" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Additional Information" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Signature Fallback:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblSignatureFallBackOrder_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="NIS Sig Last Updated:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblSigUpdates_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Last Quick Scan Src:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblLastQuickScanSource_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </Grid>
                </ScrollViewer>
                
                <!-- Panel 2: Attack Surface Reduction -->
                <Grid Name="panelASR" Margin="10" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Style="{StaticResource SectionBorder}">
                        <StackPanel>
                            <Label Content="Attack Surface Reduction Rules" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="Attack Surface Reduction (ASR) rules help prevent actions that malware often abuses to compromise devices and networks. View the current ASR rule configuration on this system." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnShowASR" Content="Show ASR Rules" Style="{StaticResource ActionButton}" Width="180"/>
                            </WrapPanel>
                            <TextBlock Text="Note: ASR rules can be configured via Group Policy, Intune, or PowerShell. Rules can be set to Block, Audit, or Warn mode." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Style="{StaticResource SectionBorder}" Margin="0,10,0,0">
                        <StackPanel>
                            <Label Content="ASR Per-Rule Exclusions" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="View per-rule ASR exclusions configured via Group Policy or Intune. These exclusions are applied to specific ASR rules and are stored in the registry." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnShowASRExclusions" Content="Show Per-Rule Exclusions" Style="{StaticResource ActionButton}" Width="220"/>
                            </WrapPanel>
                            <TextBlock Text="Note: Per-rule exclusions are read from HKLM:\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR. Global ASR exclusions can be found under the Exclusions menu." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="2" Style="{StaticResource SectionBorder}" Margin="0,10,0,0">
                        <StackPanel>
                            <Label Content="Exploit Protection" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="Exploit Protection applies mitigation techniques to apps to prevent exploitation. View the current exploit protection configuration XML file." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnOpenExploitProtectionXML" Content="Open Exploit Protection XML" Style="{StaticResource ActionButton}" Width="220"/>
                            </WrapPanel>
                            <TextBlock Text="Note: The exploit protection XML can be exported using 'Get-ProcessMitigation -RegistryConfigFilePath' or configured via Windows Security settings." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>
                </Grid>
                
                <!-- Panel 3: Exclusions -->
                <Grid Name="panelExclusions" Margin="10" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Style="{StaticResource SectionBorder}">
                        <StackPanel>
                            <Label Content="Defender AV Exclusions" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="Exclusions allow you to exclude specific files, folders, processes, or file extensions from Microsoft Defender Antivirus scanning. View the current exclusion configuration on this system." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnExclusions" Content="Show Exclusions" Style="{StaticResource ActionButton}" Width="180"/>
                            </WrapPanel>
                            <TextBlock Text="Note: Exclusions can be configured via Group Policy, Intune, or PowerShell. Use exclusions carefully as they can reduce protection." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Style="{StaticResource SectionBorder}" Margin="0,10,0,0">
                        <StackPanel>
                            <Label Content="Registry Key Information" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="300"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Label Grid.Row="0" Grid.Column="0" Content="ManagedDefenderProductType:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="0" Grid.Column="1" Name="lblManagedDefenderProductType" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                <Label Grid.Row="1" Grid.Column="0" Content="EnrollmentStatus:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="1" Grid.Column="1" Name="lblEnrollmentStatus" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                <Label Grid.Row="2" Grid.Column="0" Content="HideExclusionsFromLocalAdmins:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="2" Grid.Column="1" Name="lblHideExclusionsFromLocalAdmins" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                <Label Grid.Row="3" Grid.Column="0" Content="DisableLocalAdminMerge:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="3" Grid.Column="1" Name="lblDisableLocalAdminMerge" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                <Label Grid.Row="4" Grid.Column="0" Content="TPExclusions:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="4" Grid.Column="1" Name="lblTPExclusions" Content="N/A" Style="{StaticResource ValueLabel}"/>
                            </Grid>
                            <TextBlock Text="TPExclusions is located at HKLM\SOFTWARE\Microsoft\Windows Defender\Features. Value 1 = Exclusions are tamper protected. Value 0 = Tamper protection is not currently protecting exclusions." TextWrapping="Wrap" Margin="0,10,0,5" FontFamily="Segoe UI" FontSize="11" Foreground="#888" FontStyle="Italic"/>
                            <TextBlock Name="txtManagementStatus" Text="N/A" TextWrapping="Wrap" Margin="0,5,0,0" FontFamily="Segoe UI" FontSize="12" FontWeight="Bold" Foreground="#666"/>
                        </StackPanel>
                    </Border>
                </Grid>
                
                <!-- Panel 4: Updates -->
                <ScrollViewer Name="panelUpdates" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <Grid Margin="10">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                        
                        <Border Grid.Column="0" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Current Signature Information" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="170"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="AV Signature Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblAntivirusSigVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="AV Signature Age:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblAntivirusSigAge_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="AV Sig Last Updated:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblAntivirusSigLastUpdated_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="AS Signature Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblAntispywareSigVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="0" Content="AS Signature Age:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="4" Grid.Column="1" Name="lblAntispywareSigAge_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="0" Content="NIS Signature Version:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="5" Grid.Column="1" Name="lblSignatureVersion_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <Border Grid.Column="1" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Latest Microsoft Versions" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="MS Latest Engine:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblLastestEngineVersion_txt" Content="Click 'Check for Updates'" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="MS Latest Platform:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblLastestPlatformVersion_txt" Content="Click 'Check for Updates'" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="MS Latest Signature:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblLatestSigVersion_txt" Content="Click 'Check for Updates'" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <Border Grid.Column="0" Grid.ColumnSpan="2" Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Update Actions" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <WrapPanel>
                                    <Button Name="btnCheckForLastestUpdate" Content="Check for Latest Updates" Style="{StaticResource ActionButton}" Width="220"/>
                                    <Button Name="btnUpdateIntel" Content="Update Intel Signatures" Style="{StaticResource ActionButton}" Width="220"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                    </Grid>
                </ScrollViewer>
                
                <!-- Panel 3: Logs -->
                <Grid Name="panelLogs" Margin="10" Visibility="Collapsed">
                    <Border Style="{StaticResource SectionBorder}">
                        <StackPanel>
                            <Label Content="Event Log Viewers" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="View Windows event logs related to Microsoft Defender for Endpoint." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnShowSenseLogs" Content="Show SENSE Logs" Style="{StaticResource ActionButton}" Width="200"/>
                                <Button Name="btnShowDefenderAVLogs" Content="Show Defender AV Logs" Style="{StaticResource ActionButton}" Width="200"/>
                            </WrapPanel>
                            <TextBlock Text="Note: SENSE logs show EDR sensor activity. Defender AV logs show antivirus events." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                            <Label Content="Security Event Exports" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,20,0,10"/>
                            <TextBlock Text="Export filtered Event Viewer logs for ASR and Exploit Guard events." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <WrapPanel>
                                <Button Name="btnExportASRBlockEvents" Content="ASR Block Events" Style="{StaticResource ActionButton}" Width="180"/>
                                <Button Name="btnExportASRAuditEvents" Content="Controlled Folder Access" Style="{StaticResource ActionButton}" Width="200"/>
                                <Button Name="btnExportExploitGuardEvents" Content="Exploit Guard Events" Style="{StaticResource ActionButton}" Width="200"/>
                            </WrapPanel>
                            <TextBlock Text="ASR Block: EventID 1121/1122/5007 | Controlled Folder Access: EventID 1123/1124/5007 | Exploit Guard: Security-Mitigations and Win32k events." TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>
                </Grid>
                
                <!-- Panel 4: Performance -->
                <ScrollViewer Name="panelPerformance" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <Grid Margin="10">
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                        <Border Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Performance Recording" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <TextBlock Text="Start a performance recording to capture Defender scan activity." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                                <WrapPanel>
                                    <Button Name="btnRunPerformance" Content="Run Performance Analyzer" Style="{StaticResource ActionButton}" Width="220"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                        <Border Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Report Options" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <WrapPanel>
                                    <CheckBox Name="rdbOverview" Content="Overview" Margin="10,5" IsChecked="True" FontFamily="Segoe UI"/>
                                    <CheckBox Name="rdbTopfiles" Content="Top 10 Files" Margin="10,5" FontFamily="Segoe UI"/>
                                    <CheckBox Name="rdbTopExtensions" Content="Top 10 Extensions" Margin="10,5" FontFamily="Segoe UI"/>
                                    <CheckBox Name="rdbTopProcess" Content="Top 10 Processes" Margin="10,5" FontFamily="Segoe UI"/>
                                    <CheckBox Name="rdbTopScans" Content="Top 10 Scans" Margin="10,5" FontFamily="Segoe UI"/>
                                </WrapPanel>
                                <WrapPanel Margin="0,10,0,0">
                                    <Button Name="btnShowPerformanceReport" Content="Show Performance Report" Style="{StaticResource ActionButton}" Width="220"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                        <Border Grid.Row="2" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Estimated Impact (MPlog)" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <TextBlock Text="View estimated impact entries from the Microsoft Defender MPlog file." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                                <WrapPanel>
                                    <Button Name="btnShowEstimatedImpact" Content="Show Estimated Impact (MPlog)" Style="{StaticResource ActionButton}" Width="240"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                        <Border Grid.Row="3" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Client Analyzer" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <TextBlock Text="Download the official Microsoft Defender Client Analyzer tool." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                                <Button Name="btnDownloadClientAnalyzer" Content="Download Client Analyzer" Style="{StaticResource ActionButton}" Width="220" HorizontalAlignment="Left"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </ScrollViewer>
                
                <!-- Panel 5: Proxy -->
                <Grid Name="panelProxy" Margin="10" Visibility="Collapsed">
                    <Border Style="{StaticResource SectionBorder}">
                        <StackPanel>
                            <Label Content="Proxy Configuration" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                            <TextBlock Text="Current proxy settings configured for Microsoft Defender:" TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                            <Grid>
                                <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                <Label Grid.Row="0" Grid.Column="0" Content="Proxy URL:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="0" Grid.Column="1" Name="lblproxy_text" Content="No URL configured" Style="{StaticResource ValueLabel}"/>
                                <Label Grid.Row="1" Grid.Column="0" Content="Proxy PAC:" Style="{StaticResource HeaderLabel}"/>
                                <Label Grid.Row="1" Grid.Column="1" Name="lblProxyPac_Text" Content="No PAC configured" Style="{StaticResource ValueLabel}"/>
                            </Grid>
                            <TextBlock Text="Note: Proxy settings affect how Defender communicates with Microsoft cloud services." TextWrapping="Wrap" Margin="0,20,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                        </StackPanel>
                    </Border>
                </Grid>
                
                <!-- Panel 6: Firewall -->
                <ScrollViewer Name="panelFirewall" VerticalScrollBarVisibility="Visible" Visibility="Collapsed">
                    <Grid Margin="10">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                        
                        <Border Grid.Column="0" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Domain Profile" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblFWDomainEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Default Inbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblFWDomainInbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Default Outbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblFWDomainOutbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="Log Allowed:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblFWDomainLogAllowed_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <Border Grid.Column="1" Grid.Row="0" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Private Profile" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblFWPrivateEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Default Inbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblFWPrivateInbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Default Outbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblFWPrivateOutbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="Log Allowed:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblFWPrivateLogAllowed_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <Border Grid.Column="0" Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Public Profile" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                                    <Label Grid.Row="0" Grid.Column="0" Content="Enabled:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="0" Grid.Column="1" Name="lblFWPublicEnabled_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="0" Content="Default Inbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="1" Grid.Column="1" Name="lblFWPublicInbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="0" Content="Default Outbound:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="2" Grid.Column="1" Name="lblFWPublicOutbound_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="0" Content="Log Allowed:" Style="{StaticResource HeaderLabel}"/>
                                    <Label Grid.Row="3" Grid.Column="1" Name="lblFWPublicLogAllowed_txt" Content="N/A" Style="{StaticResource ValueLabel}"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                        
                        <Border Grid.Column="1" Grid.Row="1" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Firewall Rules" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <TextBlock Text="View and filter Windows Firewall rules." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                                <Button Name="btnShowFirewallRules" Content="Show Firewall Rules" Style="{StaticResource ActionButton}" Width="180"/>
                            </StackPanel>
                        </Border>

                        <Border Grid.Column="0" Grid.ColumnSpan="2" Grid.Row="2" Style="{StaticResource SectionBorder}">
                            <StackPanel>
                                <Label Content="Firewall Logs" FontSize="14" FontWeight="Bold" Foreground="#2D2D44" Margin="0,0,0,10"/>
                                <TextBlock Text="View the Windows Firewall log file (pfirewall.log). Logging must be enabled via Windows Firewall with Advanced Security settings." TextWrapping="Wrap" Margin="0,0,0,15" FontFamily="Segoe UI" Foreground="#666"/>
                                <WrapPanel>
                                    <Button Name="btnShowFirewallLogs" Content="Show Firewall Logs" Style="{StaticResource ActionButton}" Width="180"/>
                                </WrapPanel>
                                <TextBlock Text="Note: Log file location: C:\Windows\System32\LogFiles\Firewall\pfirewall.log" TextWrapping="Wrap" Margin="0,15,0,0" FontFamily="Segoe UI" Foreground="#888" FontStyle="Italic"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </ScrollViewer>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# Check if script is running as admin
$adminCheck = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $adminCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Add-Type -AssemblyName 'System.Windows.Forms'
    [System.Windows.Forms.MessageBox]::Show('This script requires administrator privileges.', 'Admin Privileges Required', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

# Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml) 
try { $Form = [Windows.Markup.XamlReader]::Load($reader) }
catch { Write-Host "Unable to load Windows.Markup.XamlReader"; exit }

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) }

$WorkingPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ==================== MENU NAVIGATION ====================
$menuButtons = @{ "DefenderAV" = $btnMenuDefenderAV; "ASR" = $btnMenuASR; "Exclusions" = $btnMenuExclusions; "Updates" = $btnMenuUpdates; "Logs" = $btnMenuLogs; "Performance" = $btnMenuPerformance; "Proxy" = $btnMenuProxy; "Firewall" = $btnMenuFirewall }
$panels = @{ "DefenderAV" = $panelDefenderAV; "ASR" = $panelASR; "Exclusions" = $panelExclusions; "Updates" = $panelUpdates; "Logs" = $panelLogs; "Performance" = $panelPerformance; "Proxy" = $panelProxy; "Firewall" = $panelFirewall }

function Switch-Panel { param([string]$PanelName)
    foreach ($key in $panels.Keys) { $panels[$key].Visibility = "Collapsed"; $menuButtons[$key].Style = $Form.FindResource("MenuButton") }
    $panels[$PanelName].Visibility = "Visible"; $menuButtons[$PanelName].Style = $Form.FindResource("MenuButtonActive")
}

$btnMenuDefenderAV.Add_Click({ Switch-Panel -PanelName "DefenderAV" })
$btnMenuASR.Add_Click({ Switch-Panel -PanelName "ASR" })
$btnMenuExclusions.Add_Click({
    Switch-Panel -PanelName "Exclusions"
    LoadRegistryKeys
})
$btnMenuUpdates.Add_Click({ Switch-Panel -PanelName "Updates" })
$btnMenuLogs.Add_Click({ Switch-Panel -PanelName "Logs" })
$btnMenuPerformance.Add_Click({ Switch-Panel -PanelName "Performance" })
$btnMenuProxy.Add_Click({ Switch-Panel -PanelName "Proxy" })
$btnMenuFirewall.Add_Click({ Switch-Panel -PanelName "Firewall" })
# ==================== FUNCTIONS ====================

Function Convert-BoolValue {
    param([object]$Value)
    $bool = $null
    if ($Value -is [bool]) {
        $bool = $Value
    } elseif ($Value -eq $true -or $Value -eq "True" -or $Value -eq 1) {
        $bool = $true
    } elseif ($Value -eq $false -or $Value -eq "False" -or $Value -eq 0) {
        $bool = $false
    } else {
        return $Value
    }
    return -not $bool
}

Function GetASRRuleStatus {
    try {    
        $ASRs = @()
        $ASRValue = @()
        $asrrules = @()
        
        $asrrules += [PSCustomObject]@{ Name = "Block executable content from email client and webmail"; GUID = "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550" }
        $asrrules += [PSCustomObject]@{ Name = "Block all Office applications from creating child processes"; GUID = "D4F940AB-401B-4EFC-AADC-AD5F3C50688A" }
        $asrrules += [PSCustomObject]@{ Name = "Block Office applications from creating executable content"; GUID = "3B576869-A4EC-4529-8536-B80A7769E899" }
        $asrrules += [PSCustomObject]@{ Name = "Block Office applications from injecting code into other processes"; GUID = "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84" }
        $asrrules += [PSCustomObject]@{ Name = "Block JavaScript or VBScript from launching downloaded executable content"; GUID = "D3E037E1-3EB8-44C8-A917-57927947596D" }
        $asrrules += [PSCustomObject]@{ Name = "Block execution of potentially obfuscated scripts"; GUID = "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC" }
        $asrrules += [PSCustomObject]@{ Name = "Block Win32 API calls from Office macros"; GUID = "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B" }
        $asrrules += [PSCustomObject]@{ Name = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"; GUID = "01443614-cd74-433a-b99e-2ecdc07bfc25" }
        $asrrules += [PSCustomObject]@{ Name = "Use advanced protection against ransomware"; GUID = "c1db55ab-c21a-4637-bb3f-a12568109d35" }
        $asrrules += [PSCustomObject]@{ Name = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"; GUID = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" }
        $asrrules += [PSCustomObject]@{ Name = "Block process creations originating from PSExec and WMI commands"; GUID = "d1e49aac-8f56-4280-b9ba-993a6d77406c" }
        $asrrules += [PSCustomObject]@{ Name = "Block untrusted and unsigned processes that run from USB"; GUID = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4" }
        $asrrules += [PSCustomObject]@{ Name = "Block Office communication application from creating child processes"; GUID = "26190899-1602-49e8-8b27-eb1d0a1ce869" }
        $asrrules += [PSCustomObject]@{ Name = "Block Adobe Reader from creating child processes"; GUID = "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" }
        $asrrules += [PSCustomObject]@{ Name = "Block persistence through WMI event subscription"; GUID = "e6db77e5-3df2-4cf1-b95a-636979351e5b" }
        $asrrules += [PSCustomObject]@{ Name = "Block abuse of exploited vulnerable signed drivers"; GUID = "56a863a9-875e-4185-98a7-b882c64b5ce5" }
        $asrrules += [PSCustomObject]@{ Name = "Block rebooting machine in Safe Mode"; GUID = "33ddedf1-c6e0-47cb-833e-de6133960387" }
        $asrrules += [PSCustomObject]@{ Name = "Block use of copied or impersonated system tools"; GUID = "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb" }
        $asrrules += [PSCustomObject]@{ Name = "Block Webshell creation for Servers"; GUID = "a8f5898e-1dc8-49a9-9878-85004b8a61e6" }

        $enabledvalues = "Not Enabled", "Enabled", "Audit", "NA3", "NA4", "NA5", "Warning"
        $results = Get-MpPreference

        if (-not [string]::IsNullOrEmpty($results.AttackSurfaceReductionRules_ids)) {
            foreach ($id in $asrrules.GUID) {      
                $index = [Array]::FindIndex($asrrules, [Predicate[object]]{ param($r) $r.GUID -eq $id })
                if ($index -eq -1) { continue }
                
                $count = 0
                foreach ($entry in $results.AttackSurfaceReductionRules_ids) {
                    if ($entry -match $id) {
                        $enabled = $results.AttackSurfaceReductionRules_actions[$count]             
                        if ($enabled -in 0,1,2,6) {
                            $ASRs += $asrrules[$index].Name
                            $ASRValue += $enabledvalues[$enabled]
                        }
                    }
                    $count++         
                }    
            }

            $Results = for ($i = 0; $i -lt $ASRs.Count; $i++) {
                [PSCustomObject]@{
                    ASR    = $ASRs[$i]
                    Status = $ASRValue[$i] 
                }
            }
            return $Results 
        }
        else {
            return "ASR rules empty"
        }
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
}

Function GetASRPerRuleExclusions {
    try {
        $asrrules = @(
            [PSCustomObject]@{ Name = "Block executable content from email client and webmail"; GUID = "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550" }
            [PSCustomObject]@{ Name = "Block all Office applications from creating child processes"; GUID = "D4F940AB-401B-4EFC-AADC-AD5F3C50688A" }
            [PSCustomObject]@{ Name = "Block Office applications from creating executable content"; GUID = "3B576869-A4EC-4529-8536-B80A7769E899" }
            [PSCustomObject]@{ Name = "Block Office applications from injecting code into other processes"; GUID = "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84" }
            [PSCustomObject]@{ Name = "Block JavaScript or VBScript from launching downloaded executable content"; GUID = "D3E037E1-3EB8-44C8-A917-57927947596D" }
            [PSCustomObject]@{ Name = "Block execution of potentially obfuscated scripts"; GUID = "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC" }
            [PSCustomObject]@{ Name = "Block Win32 API calls from Office macros"; GUID = "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B" }
            [PSCustomObject]@{ Name = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"; GUID = "01443614-cd74-433a-b99e-2ecdc07bfc25" }
            [PSCustomObject]@{ Name = "Use advanced protection against ransomware"; GUID = "c1db55ab-c21a-4637-bb3f-a12568109d35" }
            [PSCustomObject]@{ Name = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"; GUID = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" }
            [PSCustomObject]@{ Name = "Block process creations originating from PSExec and WMI commands"; GUID = "d1e49aac-8f56-4280-b9ba-993a6d77406c" }
            [PSCustomObject]@{ Name = "Block untrusted and unsigned processes that run from USB"; GUID = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4" }
            [PSCustomObject]@{ Name = "Block Office communication application from creating child processes"; GUID = "26190899-1602-49e8-8b27-eb1d0a1ce869" }
            [PSCustomObject]@{ Name = "Block Adobe Reader from creating child processes"; GUID = "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" }
            [PSCustomObject]@{ Name = "Block persistence through WMI event subscription"; GUID = "e6db77e5-3df2-4cf1-b95a-636979351e5b" }
            [PSCustomObject]@{ Name = "Block abuse of exploited vulnerable signed drivers"; GUID = "56a863a9-875e-4185-98a7-b882c64b5ce5" }
            [PSCustomObject]@{ Name = "Block rebooting machine in Safe Mode"; GUID = "33ddedf1-c6e0-47cb-833e-de6133960387" }
            [PSCustomObject]@{ Name = "Block use of copied or impersonated system tools"; GUID = "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb" }
            [PSCustomObject]@{ Name = "Block Webshell creation for Servers"; GUID = "a8f5898e-1dc8-49a9-9878-85004b8a61e6" }
        )

        $basePath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR"
        $results = @()

        # Check global ASR exclusions
        $globalExclPath = "$basePath\ASROnlyExclusions"
        if (Test-Path $globalExclPath) {
            $globalExcl = Get-ItemProperty -Path $globalExclPath -ErrorAction SilentlyContinue
            if ($globalExcl) {
                $globalExcl.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    $results += [PSCustomObject]@{
                        Rule      = "(Global ASR Exclusion)"
                        Exclusion = $_.Name
                    }
                }
            }
        }

        # Check per-rule exclusions
        $rulesExclPath = "$basePath\Rules"
        if (Test-Path $rulesExclPath) {
            $ruleGuids = Get-ChildItem -Path $rulesExclPath -ErrorAction SilentlyContinue
            foreach ($ruleKey in $ruleGuids) {
                $ruleGuid = $ruleKey.PSChildName
                $ruleName = ($asrrules | Where-Object { $_.GUID -ieq $ruleGuid }).Name
                if (-not $ruleName) { $ruleName = "Unknown rule ($ruleGuid)" }

                $ruleProps = Get-ItemProperty -Path $ruleKey.PSPath -ErrorAction SilentlyContinue
                if ($ruleProps) {
                    $ruleProps.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                        $results += [PSCustomObject]@{
                            Rule      = $ruleName
                            Exclusion = $_.Name
                        }
                    }
                }
            }
        }

        if ($results.Count -eq 0) {
            return "No per-rule ASR exclusions found"
        }

        return $results
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error') }
}

Function LoadRegistryKeys {
    $managedDefenderValue = $null
    $enrollmentValue = $null
    $disableLocalAdminMergeEnabled = $false

    try {
        $ManagedDefenderProductType = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "ManagedDefenderProductType" -ErrorAction SilentlyContinue
        if ($ManagedDefenderProductType) {
            $managedDefenderValue = $ManagedDefenderProductType.ManagedDefenderProductType
        }
    } catch {
        $lblManagedDefenderProductType.Content = "Error reading registry"
        $lblManagedDefenderProductType.Foreground = "#FFFF0000"
        $lblEnrollmentStatus.Content = "Error reading registry"
        $lblEnrollmentStatus.Foreground = "#FFFF0000"
        $txtManagementStatus.Text = "Error reading registry"
        $txtManagementStatus.Foreground = "#FFFF0000"
        return
    }

    try {
        $EnrollmentStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\SenseCM" -Name "EnrollmentStatus" -ErrorAction SilentlyContinue
        if ($EnrollmentStatus) {
            $enrollmentValue = $EnrollmentStatus.EnrollmentStatus
        }
    } catch {
        $lblEnrollmentStatus.Content = "Error reading registry"
        $lblEnrollmentStatus.Foreground = "#FFFF0000"
        $txtManagementStatus.Text = "Error reading registry"
        $txtManagementStatus.Foreground = "#FFFF0000"
        return
    }

    # Check DisableLocalAdminMerge first (needed for tamper protection validation)
    try {
        $DisableLocalAdminMerge = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableLocalAdminMerge" -ErrorAction SilentlyContinue
        if ($DisableLocalAdminMerge -and $DisableLocalAdminMerge.DisableLocalAdminMerge -ne 0) {
            $disableLocalAdminMergeEnabled = $true
            $lblDisableLocalAdminMerge.Content = "Enabled"
            $lblDisableLocalAdminMerge.Foreground = "#FF008000"
        } else {
            $lblDisableLocalAdminMerge.Content = "Not Configured"
            $lblDisableLocalAdminMerge.Foreground = "#FF888888"
        }
    } catch {
        $lblDisableLocalAdminMerge.Content = "Not Configured"
        $lblDisableLocalAdminMerge.Foreground = "#FF888888"
    }

    # Check HideExclusionsFromLocalAdmins
    try {
        $HideExclusions = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "HideExclusionsFromLocalAdmins" -ErrorAction SilentlyContinue
        if ($HideExclusions -and $HideExclusions.HideExclusionsFromLocalAdmins -ne 0) {
            $lblHideExclusionsFromLocalAdmins.Content = "Enabled"
            $lblHideExclusionsFromLocalAdmins.Foreground = "#FF008000"
        } else {
            $lblHideExclusionsFromLocalAdmins.Content = "Not Configured"
            $lblHideExclusionsFromLocalAdmins.Foreground = "#FF888888"
        }
    } catch {
        $lblHideExclusionsFromLocalAdmins.Content = "Not Configured"
        $lblHideExclusionsFromLocalAdmins.Foreground = "#FF888888"
    }

    # TPExclusions
    try {
        $tpExclusionsValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TPExclusions" -ErrorAction SilentlyContinue
        if ($null -ne $tpExclusionsValue) {
            if ($tpExclusionsValue.TPExclusions -eq 1) {
                $lblTPExclusions.Content = "1 - Exclusions are tamper protected"
                $lblTPExclusions.Foreground = "#FF008000"
            } else {
                $lblTPExclusions.Content = "0 - Tamper protection not protecting exclusions"
                $lblTPExclusions.Foreground = "#FFFF8C00"
            }
        } else {
            $lblTPExclusions.Content = "Not Found"
            $lblTPExclusions.Foreground = "#FF888888"
        }
    } catch {
        $lblTPExclusions.Content = "Error reading registry"
        $lblTPExclusions.Foreground = "#FFFF0000"
    }

    # Determine management status based on the table
    $managementStatus = ""

    if ($null -eq $managedDefenderValue -or $null -eq $enrollmentValue) {
        $managementStatus = "Device management status unknown"
        $lblManagedDefenderProductType.Content = if ($null -eq $managedDefenderValue) { "Not Found" } else { $managedDefenderValue }
        $lblEnrollmentStatus.Content = if ($null -eq $enrollmentValue) { "Not Found" } else { $enrollmentValue }
        $lblManagedDefenderProductType.Foreground = "#FF888888"
        $lblEnrollmentStatus.Foreground = "#FF888888"
        $txtManagementStatus.Text = $managementStatus
        $txtManagementStatus.Foreground = "#FF888888"
    }
    elseif ($managedDefenderValue -eq 6) {
        $lblManagedDefenderProductType.Content = $managedDefenderValue
        $lblEnrollmentStatus.Content = $enrollmentValue
        $lblManagedDefenderProductType.Foreground = "#FF000000"
        $lblEnrollmentStatus.Foreground = "#FF000000"

        if ($disableLocalAdminMergeEnabled) {
            $managementStatus = "Device is managed with Intune only. Exclusions ARE tamper protected."
            $txtManagementStatus.Text = $managementStatus
            $txtManagementStatus.Foreground = "#FF008000"
        } else {
            $managementStatus = "Device is managed with Intune only. To enable tamper protection for exclusions, you need to enable DisableLocalAdminMerge first."
            $txtManagementStatus.Text = $managementStatus
            $txtManagementStatus.Foreground = "#FFFF6600"
        }
    }
    elseif ($managedDefenderValue -eq 7 -and $enrollmentValue -eq 4) {
        $lblManagedDefenderProductType.Content = $managedDefenderValue
        $lblEnrollmentStatus.Content = $enrollmentValue
        $lblManagedDefenderProductType.Foreground = "#FF000000"
        $lblEnrollmentStatus.Foreground = "#FF000000"

        if ($disableLocalAdminMergeEnabled) {
            $managementStatus = "Device is managed with Configuration Manager. Exclusions ARE tamper protected."
            $txtManagementStatus.Text = $managementStatus
            $txtManagementStatus.Foreground = "#FF008000"
        } else {
            $managementStatus = "Device is managed with Configuration Manager. To enable tamper protection for exclusions, you need to enable DisableLocalAdminMerge first."
            $txtManagementStatus.Text = $managementStatus
            $txtManagementStatus.Foreground = "#FFFF6600"
        }
    }
    elseif ($managedDefenderValue -eq 7 -and $enrollmentValue -eq 3) {
        $managementStatus = "Device is co-managed with Configuration Manager and Intune. This is NOT supported for exclusions to be tamper protected."
        $lblManagedDefenderProductType.Content = $managedDefenderValue
        $lblEnrollmentStatus.Content = $enrollmentValue
        $lblManagedDefenderProductType.Foreground = "#FF000000"
        $lblEnrollmentStatus.Foreground = "#FF000000"
        $txtManagementStatus.Text = $managementStatus
        $txtManagementStatus.Foreground = "#FFFF6600"
    }
    else {
        $managementStatus = "Device is not managed by Intune only or Configuration Manager only. Exclusions are NOT tamper protected."
        $lblManagedDefenderProductType.Content = $managedDefenderValue
        $lblEnrollmentStatus.Content = $enrollmentValue
        $lblManagedDefenderProductType.Foreground = "#FF000000"
        $lblEnrollmentStatus.Foreground = "#FF000000"
        $txtManagementStatus.Text = $managementStatus
        $txtManagementStatus.Foreground = "#FFFF0000"
    }
}

Function GetSignatureVersion {
    try {
        $website = Invoke-WebRequest -Uri https://www.microsoft.com/en-us/wdsi/definitions/antimalware-definition-release-notes -UseBasicParsing
        $Pattern = '<span id="(?<dropdown>.*)" tabindex=(?<tabindex>.*) aria-label=(?<arialabel>.*) versionid=(?<versionid>.*)>(?<version>.*)</span>'
        $AllMatches = ($website | Select-String $Pattern -AllMatches).Matches

        $SignatureVersionList = foreach ($group in $AllMatches) {
            [PSCustomObject]@{
                'version' = ($group.Groups.Where{ $_.Name -like 'version' }).Value
            }
        }

        $SignatureCurrentVersion = $SignatureVersionList | Select-Object -First 1
        return $SignatureCurrentVersion.version
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
}

Function GetPlatformVersionAndEngine {
    try {
        $PlatformURL = "https://www.microsoft.com/en-us/wdsi/defenderupdates?ranMID=24542&ranEAID=TnL5HPStwNw&ranSiteID=TnL5HPStwNw-ywv7diDw5Zx1d5vlZitDSQ&epi=TnL5HPStwNw-ywv7diDw5Zx1d5vlZitDSQ&irgwc=1&OCID=AID2000142_aff_7593_1243925&tduid=%28ir__cdyqnmiqgckftliekk0sohzjxn2xpksmaywdhgac00%29%287593%29%281243925%29%28TnL5HPStwNw-ywv7diDw5Zx1d5vlZitDSQ%29%28%29&irclickid=_cdyqnmiqgckftliekk0sohzjxn2xpksmaywdhgac00"

        $Platformwebsite = Invoke-WebRequest -Uri $PlatformURL -UseBasicParsing
        $PlatformPattern = "<li>Platform Version: <span>(?<Platform>.*)</span></li>" 
        $PlatformMatches = ($Platformwebsite | Select-String $PlatformPattern -AllMatches).Matches
        
        $PlatformVersionList = foreach ($group in $PlatformMatches) {
            [PSCustomObject]@{
                'Platform_Version' = ($group.Groups.Where{ $_.Name -like 'Platform' }).Value
            }
        }

        $CurrentPlatformVersion = ($PlatformVersionList).Platform_Version

        $EnginePattern = "<li>Engine Version: <span>(?<Engine>.*)</span></li>"
        $EngineMatches = ($Platformwebsite | Select-String $EnginePattern -AllMatches).Matches

        $EngineVersionList = foreach ($group in $EngineMatches) {
            [PSCustomObject]@{
                'Engine_Version' = ($group.Groups.Where{ $_.Name -like 'Engine' }).Value
            }
        }

        $CurrentEngineVersion = ($EngineVersionList).Engine_Version
        return $CurrentPlatformVersion, $CurrentEngineVersion
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
}

Function ReadHashComputation {
    if (Test-Path "HKLM:\Software\Policies\Microsoft\Windows Defender\MpEngine") {
        $KeyReadHashComputation = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\MpEngine" -Name "EnableFileHashComputation" -ErrorAction SilentlyContinue
        if ($KeyReadHashComputation) {
            return "Enabled by GPO"
        }
    }
    
    if (Test-Path "HKLM:\Software\Microsoft\Windows Defender\MpEngine") {
        $KeyReadHashComputation = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows Defender\MpEngine" -Name "EnableFileHashComputation" -ErrorAction SilentlyContinue
        if ($KeyReadHashComputation) {
            return "Enabled"
        }
    }
    
    return "Disabled"
}

Function WindowLoader {
    try {
        $MPpreference = Get-MpPreference
        $MPComputerstatus = Get-MpComputerStatus

        # Version Information
        $lblAMEngineVersion_txt.Content = $MPComputerstatus.AMEngineVersion
        $lblAMProductVersion_txt.Content = $MPComputerstatus.AMProductVersion
        $lblAMServiceVersion_txt.Content = $MPComputerstatus.AMServiceVersion
        $lblNISEngineVersion_txt.Content = $MPComputerstatus.NISEngineVersion
        $lblAMRunningMode_txt.Content = $MPComputerstatus.AMRunningMode
        $lblComputerState_txt.Content = $MPComputerstatus.ComputerState
        
        # Service Status
        $lblAMServiceEnabled_txt.Content = $MPComputerstatus.AMServiceEnabled
        $lblAntivirusEnabled_txt.Content = $MPComputerstatus.AntivirusEnabled
        $lblAntispywareEnabled_txt.Content = $MPComputerstatus.AntispywareEnabled
        $lblNISEnabled_txt.Content = $MPComputerstatus.NISEnabled
        $lblIsVirtualMachine_txt.Content = $MPComputerstatus.IsVirtualMachine
        $lblComputerID_txt.Content = $MPComputerstatus.ComputerID
        
        # Real-Time Protection
        $lblRealTimeProtection_txt.Content = $MPComputerstatus.RealTimeProtectionEnabled
        $lblOnAccessProtection_txt.Content = $MPComputerstatus.OnAccessProtectionEnabled
        $lblBehaviorMonitor_txt.Content = $MPComputerstatus.BehaviorMonitorEnabled
        $lblIoavProtection_txt.Content = $MPComputerstatus.IoavProtectionEnabled
        $lblTamper_txt.Content = $MPComputerstatus.IsTamperProtected
        $lblTamperSource_txt.Content = $MPComputerstatus.TamperProtectionSource
        
        # Signature Information
        $lblAntivirusSigVersion_txt.Content = $MPComputerstatus.AntivirusSignatureVersion
        $lblAntivirusSigAge_txt.Content = "$($MPComputerstatus.AntivirusSignatureAge) days"
        $lblAntivirusSigLastUpdated_txt.Content = $MPComputerstatus.AntivirusSignatureLastUpdated
        $lblAntispywareSigVersion_txt.Content = $MPComputerstatus.AntispywareSignatureVersion
        $lblAntispywareSigAge_txt.Content = "$($MPComputerstatus.AntispywareSignatureAge) days"
        $lblSignatureVersion_txt.Content = $MPComputerstatus.NISSignatureVersion
        
        # Scan Information
        $lblFullScanAge_txt.Content = if ($MPComputerstatus.FullScanAge -eq 4294967295) { "Never" } else { "$($MPComputerstatus.FullScanAge) days" }
        $lblFullScanStartTime_txt.Content = if ($MPComputerstatus.FullScanStartTime) { $MPComputerstatus.FullScanStartTime } else { "Never" }
        $lblFullScanEndTime_txt.Content = if ($MPComputerstatus.FullScanEndTime) { $MPComputerstatus.FullScanEndTime } else { "Never" }
        $lblQuickScanAge_txt.Content = if ($MPComputerstatus.QuickScanAge -eq 4294967295) { "Never" } else { "$($MPComputerstatus.QuickScanAge) days" }
        $lblQuickScanStartTime_txt.Content = if ($MPComputerstatus.QuickScanStartTime) { $MPComputerstatus.QuickScanStartTime } else { "Never" }
        $lblQuickScanEndTime_txt.Content = if ($MPComputerstatus.QuickScanEndTime) { $MPComputerstatus.QuickScanEndTime } else { "Never" }
        
        # Additional Information
        $lblSignatureFallBackOrder_txt.Content = $MPpreference.SignatureFallbackOrder
        $lblSigUpdates_txt.Content = $MPComputerstatus.NISSignatureLastUpdated
        $scanSourceMap = @{ 0 = "Unknown"; 1 = "User"; 2 = "System"; 3 = "Real-time"; 4 = "IOAV" }
        $lblLastQuickScanSource_txt.Content = if ($scanSourceMap.ContainsKey([int]$MPComputerstatus.LastQuickScanSource)) { $scanSourceMap[[int]$MPComputerstatus.LastQuickScanSource] } else { $MPComputerstatus.LastQuickScanSource }
        
        # Protection Settings (from Get-MpPreference)
        $lblQuarantine_text.Content = $MPpreference.QuarantinePurgeItemsAfterDelay
        $lblPUAProtect_text.Content = Convert-BoolValue -Value $MPpreference.DisableBlockAtFirstSeen
        $lblCloudTimeout_text.Content = $MPpreference.CloudExtendedTimeout
        $lblDeviceControl_Text.Content = $MPComputerstatus.DeviceControlState
        
        # Header info
        $lblComputerName.Content = [System.Net.Dns]::GetHostName()

        if ($MPpreference.ProxyPacUrl) {
            $lblProxyPac_Text.Content = $MPpreference.ProxyPacUrl
        } else {
            $lblProxyPac_Text.Content = "No Proxy PAC Configured"
        }

        if ($MPpreference.ProxyServer) {
            $lblproxy_text.Content = $MPpreference.ProxyServer
        } else {
            $lblproxy_text.Content = "No Proxy URL Configured"
        }

        $lblEnableFileHashComputation_Text.Content = ReadHashComputation

        switch ($MPpreference.CloudBlockLevel) {
            0 { $lblCloudBlockLevel_txt.Content = "Default" }
            1 { $lblCloudBlockLevel_txt.Content = "Moderate" }
            2 { $lblCloudBlockLevel_txt.Content = "High" }
            3 { $lblCloudBlockLevel_txt.Content = "High+" }
            4 { $lblCloudBlockLevel_txt.Content = "Zero tolerance" }
        }
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }

    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status") {
        $RegisteryOrgID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name "OrgId" -ErrorAction SilentlyContinue).OrgId 
        $lblOrgID_txt.Content = $RegisteryOrgID
    }
    
    # Load Firewall Profile Status
    try {
        $FWProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        
        foreach ($profile in $FWProfiles) {
            switch ($profile.Name) {
                "Domain" {
                    $lblFWDomainEnabled_txt.Content = $profile.Enabled
                    $lblFWDomainInbound_txt.Content = $profile.DefaultInboundAction
                    $lblFWDomainOutbound_txt.Content = $profile.DefaultOutboundAction
                    $lblFWDomainLogAllowed_txt.Content = $profile.LogAllowed
                }
                "Private" {
                    $lblFWPrivateEnabled_txt.Content = $profile.Enabled
                    $lblFWPrivateInbound_txt.Content = $profile.DefaultInboundAction
                    $lblFWPrivateOutbound_txt.Content = $profile.DefaultOutboundAction
                    $lblFWPrivateLogAllowed_txt.Content = $profile.LogAllowed
                }
                "Public" {
                    $lblFWPublicEnabled_txt.Content = $profile.Enabled
                    $lblFWPublicInbound_txt.Content = $profile.DefaultInboundAction
                    $lblFWPublicOutbound_txt.Content = $profile.DefaultOutboundAction
                    $lblFWPublicLogAllowed_txt.Content = $profile.LogAllowed
                }
            }
        }
    }
    catch { }
}

Function Show-EstimatedImpactWindow {
    param(
        [Parameter(Mandatory=$true)]$ImpactData
    )

    $impactXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Estimated Impact - MPlog" Height="700" Width="1200" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1000">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="Estimated Impact - MPlog" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtImpactCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="1" Name="dgImpact" AutoGenerateColumns="True" IsReadOnly="True" Background="White"
                  AlternatingRowBackground="#F9F9F9" GridLinesVisibility="Horizontal" HeadersVisibility="Column"
                  CanUserSortColumns="True" CanUserResizeColumns="True" CanUserReorderColumns="True"
                  HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
            <DataGrid.ColumnHeaderStyle>
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#2D2D44"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Padding" Value="10,5"/>
                    <Setter Property="BorderBrush" Value="#1A1A2E"/>
                    <Setter Property="BorderThickness" Value="0,0,1,0"/>
                </Style>
            </DataGrid.ColumnHeaderStyle>
            <DataGrid.RowStyle>
                <Style TargetType="DataGridRow">
                    <Setter Property="Height" Value="30"/>
                </Style>
            </DataGrid.RowStyle>
        </DataGrid>
    </Grid>
</Window>
"@

    $impactReader = (New-Object System.Xml.XmlNodeReader ([xml]$impactXaml))
    $impactWindow = [Windows.Markup.XamlReader]::Load($impactReader)

    # Get controls
    $dgImpact = $impactWindow.FindName("dgImpact")
    $txtImpactCount = $impactWindow.FindName("txtImpactCount")

    # Set data
    $dgImpact.ItemsSource = $ImpactData
    $txtImpactCount.Text = "Showing $($ImpactData.Count) estimated impact entries"

    $impactWindow.ShowDialog() | Out-Null
}

Function Show-PerformanceReportWindow {
    param(
        [Parameter(Mandatory=$true)]$ReportData,
        [Parameter(Mandatory=$true)][string]$Title
    )

    $perfXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$Title" Height="700" Width="1200" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1000">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="$Title" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtPerfCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="1" Name="dgPerformance" AutoGenerateColumns="True" IsReadOnly="True" Background="White"
                  AlternatingRowBackground="#F9F9F9" GridLinesVisibility="Horizontal" HeadersVisibility="Column"
                  CanUserSortColumns="True" CanUserResizeColumns="True" CanUserReorderColumns="True"
                  HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
            <DataGrid.ColumnHeaderStyle>
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#2D2D44"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Padding" Value="10,5"/>
                    <Setter Property="BorderBrush" Value="#1A1A2E"/>
                    <Setter Property="BorderThickness" Value="0,0,1,0"/>
                </Style>
            </DataGrid.ColumnHeaderStyle>
            <DataGrid.RowStyle>
                <Style TargetType="DataGridRow">
                    <Setter Property="Height" Value="30"/>
                </Style>
            </DataGrid.RowStyle>
        </DataGrid>
    </Grid>
</Window>
"@

    $perfReader = (New-Object System.Xml.XmlNodeReader ([xml]$perfXaml))
    $perfWindow = [Windows.Markup.XamlReader]::Load($perfReader)

    # Get controls
    $dgPerformance = $perfWindow.FindName("dgPerformance")
    $txtPerfCount = $perfWindow.FindName("txtPerfCount")

    # Convert data to array if it's not already an enumerable collection
    $dataArray = @()
    if ($ReportData -is [Array]) {
        $dataArray = $ReportData
    } else {
        $dataArray = @($ReportData)
    }

    # Set data
    $dgPerformance.ItemsSource = $dataArray
    $txtPerfCount.Text = "Showing $($dataArray.Count) items"

    $perfWindow.ShowDialog() | Out-Null
}

Function PerformanceReport {
    try {
        if (Test-Path "$WorkingPath\MDAV_Recording.etl") {
            $PerformanceReport = Get-MpPerformanceReport -Path "$WorkingPath\MDAV_Recording.etl" -TopFiles:10 -TopExtensions:10 -TopProcesses:10 -TopScans:10 -Overview

            if ($PerformanceReport) {
                # Collect all selected reports to open
                $reportsToOpen = @()
                $missingReports = @()

                if ($rdbOverview.IsChecked -eq $true) {
                    if ($PerformanceReport.Overview) {
                        # Process Overview data to convert PerfHints array to readable text
                        $processedOverview = $PerformanceReport.Overview | Select-Object *, @{
                            Name = 'PerfHintsText'
                            Expression = {
                                if ($_.PerfHints) {
                                    ($_.PerfHints | ForEach-Object { $_.ToString() }) -join '; '
                                } else {
                                    'None'
                                }
                            }
                        } | Select-Object * -ExcludeProperty PerfHints

                        $reportsToOpen += @{Data = $processedOverview; Title = "Performance Report - Overview"}
                    } else {
                        $missingReports += "Overview"
                    }
                }

                if ($rdbTopfiles.IsChecked -eq $true) {
                    if ($PerformanceReport.TopFiles) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopFiles; Title = "Performance Report - Top Files Scans"}
                    } else {
                        $missingReports += "Top Files"
                    }
                }

                if ($rdbTopExtensions.IsChecked -eq $true) {
                    if ($PerformanceReport.TopExtensions) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopExtensions; Title = "Performance Report - Top Extensions Scans"}
                    } else {
                        $missingReports += "Top Extensions"
                    }
                }

                if ($rdbTopProcess.IsChecked -eq $true) {
                    if ($PerformanceReport.TopProcesses) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopProcesses; Title = "Performance Report - Top Processes Scans"}
                    } else {
                        $missingReports += "Top Processes"
                    }
                }

                if ($rdbTopScans.IsChecked -eq $true) {
                    if ($PerformanceReport.TopScans) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopScans; Title = "Performance Report - Top Scans"}
                    } else {
                        $missingReports += "Top Scans"
                    }
                }

                # Open all windows using runspaces to display them simultaneously
                foreach ($report in $reportsToOpen) {
                    $runspace = [runspacefactory]::CreateRunspace()
                    $runspace.ApartmentState = "STA"
                    $runspace.ThreadOptions = "ReuseThread"
                    $runspace.Open()

                    $powershell = [powershell]::Create()
                    $powershell.Runspace = $runspace

                    [void]$powershell.AddScript({
                        param($reportData, $reportTitle)

                        Add-Type -AssemblyName PresentationFramework

                        $perfXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$reportTitle" Height="700" Width="1200" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1000">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="$reportTitle" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtPerfCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="1" Name="dgPerformance" AutoGenerateColumns="True" IsReadOnly="True" Background="White"
                  AlternatingRowBackground="#F9F9F9" GridLinesVisibility="Horizontal" HeadersVisibility="Column"
                  CanUserSortColumns="True" CanUserResizeColumns="True" CanUserReorderColumns="True"
                  HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
            <DataGrid.ColumnHeaderStyle>
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#2D2D44"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Padding" Value="10,5"/>
                    <Setter Property="BorderBrush" Value="#1A1A2E"/>
                    <Setter Property="BorderThickness" Value="0,0,1,0"/>
                </Style>
            </DataGrid.ColumnHeaderStyle>
            <DataGrid.RowStyle>
                <Style TargetType="DataGridRow">
                    <Setter Property="Height" Value="30"/>
                </Style>
            </DataGrid.RowStyle>
        </DataGrid>
    </Grid>
</Window>
"@

                        $perfReader = (New-Object System.Xml.XmlNodeReader ([xml]$perfXaml))
                        $perfWindow = [Windows.Markup.XamlReader]::Load($perfReader)

                        $dgPerformance = $perfWindow.FindName("dgPerformance")
                        $txtPerfCount = $perfWindow.FindName("txtPerfCount")

                        $dataArray = @()
                        if ($reportData -is [Array]) {
                            $dataArray = $reportData
                        } else {
                            $dataArray = @($reportData)
                        }

                        # Add event handler to enable text wrapping for PerfHintsText column
                        $dgPerformance.Add_AutoGeneratingColumn({
                            param($sender, $e)
                            if ($e.PropertyName -eq "PerfHintsText") {
                                $e.Column.Width = 400
                                $style = New-Object System.Windows.Style([System.Windows.Controls.TextBlock])
                                $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextWrappingProperty, [System.Windows.TextWrapping]::Wrap)))
                                $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::PaddingProperty, (New-Object System.Windows.Thickness(5)))))
                                $e.Column.ElementStyle = $style
                            }
                        })

                        $dgPerformance.ItemsSource = $dataArray
                        $txtPerfCount.Text = "Showing $($dataArray.Count) items"

                        $perfWindow.ShowDialog() | Out-Null

                    }).AddArgument($report.Data).AddArgument($report.Title)

                    $powershell.BeginInvoke()
                    Start-Sleep -Milliseconds 200
                }

                # Show warning if any reports are missing
                if ($missingReports.Count -gt 0) {
                    [System.Windows.MessageBox]::Show("The following reports had no data: $($missingReports -join ', '). Please run the performance recording for a longer time!", 'Missing Data', 'OK', 'Warning')
                }
            } else {
                [System.Windows.MessageBox]::Show("Performance report is empty... please run again for a longer time!")
            }
        }
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
}

Function PerformanceAnalyze {
    try {
        $arg = "New-MpPerformanceRecording -RecordTo `"$WorkingPath\MDAV_Recording.etl`""
        Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $arg -Wait
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
}

Function Show-FirewallRulesWindow {
    param(
        [Parameter(Mandatory=$true)]$RulesData
    )
    
    $fwXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Windows Firewall Rules" Height="750" Width="1300" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1300" MaxWidth="1300">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="Windows Firewall Rules" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtRuleCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>
        
        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Search:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBox Name="txtSearch" Width="200" Margin="5,0" Padding="5" FontFamily="Segoe UI" VerticalContentAlignment="Center"/>
                <Separator Margin="10,0"/>
                <Label Content="Direction:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbDirection" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Inbound"/>
                    <ComboBoxItem Content="Outbound"/>
                </ComboBox>
                <Separator Margin="10,0"/>
                <Label Content="Action:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbAction" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Allow"/>
                    <ComboBoxItem Content="Block"/>
                </ComboBox>
                <Separator Margin="10,0"/>
                <Label Content="Enabled:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbEnabled" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="True"/>
                    <ComboBoxItem Content="False"/>
                </ComboBox>
                <Separator Margin="10,0"/>
                <Label Content="Profile:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbProfile" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Domain"/>
                    <ComboBoxItem Content="Private"/>
                    <ComboBoxItem Content="Public"/>
                </ComboBox>
            </StackPanel>
        </Border>
        
        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgFirewallRules" AutoGenerateColumns="False" IsReadOnly="True" 
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Name" Binding="{Binding DisplayName}" Width="250">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextTrimming" Value="CharacterEllipsis"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Enabled" Binding="{Binding Enabled}" Width="70">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Direction" Binding="{Binding Direction}" Width="80">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Action" Binding="{Binding Action}" Width="70">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Profile" Binding="{Binding Profile}" Width="120">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Protocol" Binding="{Binding Protocol}" Width="70">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Local Port" Binding="{Binding LocalPort}" Width="100">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Remote Port" Binding="{Binding RemotePort}" Width="100">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Program" Binding="{Binding Program}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextTrimming" Value="CharacterEllipsis"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

    $fwReader = (New-Object System.Xml.XmlNodeReader ([xml]$fwXaml))
    $fwWindow = [Windows.Markup.XamlReader]::Load($fwReader)
    
    # Get controls
    $dgFirewallRules = $fwWindow.FindName("dgFirewallRules")
    $txtSearch = $fwWindow.FindName("txtSearch")
    $cmbDirection = $fwWindow.FindName("cmbDirection")
    $cmbAction = $fwWindow.FindName("cmbAction")
    $cmbEnabled = $fwWindow.FindName("cmbEnabled")
    $cmbProfile = $fwWindow.FindName("cmbProfile")
    $txtRuleCount = $fwWindow.FindName("txtRuleCount")
    
    # Store original data
    $script:OriginalFWData = $RulesData
    
    # Set initial data
    $dgFirewallRules.ItemsSource = $RulesData
    $txtRuleCount.Text = "Showing $($RulesData.Count) firewall rules"
    
    # Filter function
    $ApplyFWFilters = {
        $searchText = $txtSearch.Text.ToLower()
        $directionFilter = $cmbDirection.SelectedItem.Content
        $actionFilter = $cmbAction.SelectedItem.Content
        $enabledFilter = $cmbEnabled.SelectedItem.Content
        $profileFilter = $cmbProfile.SelectedItem.Content
        
        $filtered = $script:OriginalFWData | Where-Object {
            $matchesSearch = $true
            $matchesDirection = $true
            $matchesAction = $true
            $matchesEnabled = $true
            $matchesProfile = $true
            
            if ($searchText) {
                $matchesSearch = ($_.DisplayName -like "*$searchText*") -or ($_.Program -like "*$searchText*")
            }
            
            if ($directionFilter -ne "All") {
                $matchesDirection = $_.Direction -eq $directionFilter
            }
            
            if ($actionFilter -ne "All") {
                $matchesAction = $_.Action -eq $actionFilter
            }
            
            if ($enabledFilter -ne "All") {
                $matchesEnabled = $_.Enabled -eq $enabledFilter
            }
            
            if ($profileFilter -ne "All") {
                $matchesProfile = $_.Profile -like "*$profileFilter*"
            }
            
            $matchesSearch -and $matchesDirection -and $matchesAction -and $matchesEnabled -and $matchesProfile
        }
        
        $dgFirewallRules.ItemsSource = $filtered
        $txtRuleCount.Text = "Showing $($filtered.Count) of $($script:OriginalFWData.Count) firewall rules"
    }
    
    # Event handlers
    $txtSearch.Add_TextChanged($ApplyFWFilters)
    $cmbDirection.Add_SelectionChanged($ApplyFWFilters)
    $cmbAction.Add_SelectionChanged($ApplyFWFilters)
    $cmbEnabled.Add_SelectionChanged($ApplyFWFilters)
    $cmbProfile.Add_SelectionChanged($ApplyFWFilters)
    
    $fwWindow.ShowDialog() | Out-Null
}

Function Show-FirewallLogsWindow {
    param(
        [Parameter(Mandatory=$true)]$LogData
    )

    $fwLogXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Windows Firewall Logs" Height="750" Width="1400" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1200">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="Windows Firewall Logs" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtFWLogCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Search IP:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBox Name="txtFWLogSearch" Width="150" Margin="5,0" Padding="5" FontFamily="Segoe UI" VerticalContentAlignment="Center"/>
                <Separator Margin="10,0"/>
                <Label Content="Action:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbFWLogAction" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="ALLOW"/>
                    <ComboBoxItem Content="DROP"/>
                </ComboBox>
                <Separator Margin="10,0"/>
                <Label Content="Protocol:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbFWLogProtocol" Width="100" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="TCP"/>
                    <ComboBoxItem Content="UDP"/>
                    <ComboBoxItem Content="ICMP"/>
                </ComboBox>
                <Separator Margin="10,0"/>
                <Label Content="Direction:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbFWLogDirection" Width="110" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="RECEIVE"/>
                    <ComboBoxItem Content="SEND"/>
                </ComboBox>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgFWLogs" AutoGenerateColumns="False" IsReadOnly="True"
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Date/Time" Binding="{Binding DateTime}" Width="140">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Action" Binding="{Binding Action}" Width="70">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Protocol" Binding="{Binding Protocol}" Width="75">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Src IP" Binding="{Binding SrcIP}" Width="130">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Dst IP" Binding="{Binding DstIP}" Width="130">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Src Port" Binding="{Binding SrcPort}" Width="80">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Dst Port" Binding="{Binding DstPort}" Width="80">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Direction" Binding="{Binding Path}" Width="85">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Size" Binding="{Binding Size}" Width="60">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Info" Binding="{Binding Info}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock"><Setter Property="Padding" Value="5"/><Setter Property="TextTrimming" Value="CharacterEllipsis"/></Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

    $fwLogReader = (New-Object System.Xml.XmlNodeReader ([xml]$fwLogXaml))
    $fwLogWindow = [Windows.Markup.XamlReader]::Load($fwLogReader)

    $dgFWLogs          = $fwLogWindow.FindName("dgFWLogs")
    $txtFWLogSearch    = $fwLogWindow.FindName("txtFWLogSearch")
    $cmbFWLogAction    = $fwLogWindow.FindName("cmbFWLogAction")
    $cmbFWLogProtocol  = $fwLogWindow.FindName("cmbFWLogProtocol")
    $cmbFWLogDirection = $fwLogWindow.FindName("cmbFWLogDirection")
    $txtFWLogCount     = $fwLogWindow.FindName("txtFWLogCount")

    $script:OriginalFWLogData = $LogData

    $dgFWLogs.ItemsSource = $LogData
    $txtFWLogCount.Text = "Showing $($LogData.Count) log entries"

    $ApplyFWLogFilters = {
        $searchText   = $txtFWLogSearch.Text.ToLower()
        $actionFilter = $cmbFWLogAction.SelectedItem.Content
        $protoFilter  = $cmbFWLogProtocol.SelectedItem.Content
        $dirFilter    = $cmbFWLogDirection.SelectedItem.Content

        $filtered = $script:OriginalFWLogData | Where-Object {
            $matchSearch = $true
            $matchAction = $true
            $matchProto  = $true
            $matchDir    = $true

            if ($searchText)              { $matchSearch = ($_.SrcIP -like "*$searchText*") -or ($_.DstIP -like "*$searchText*") }
            if ($actionFilter -ne "All")  { $matchAction = $_.Action   -eq $actionFilter }
            if ($protoFilter  -ne "All")  { $matchProto  = $_.Protocol -eq $protoFilter }
            if ($dirFilter    -ne "All")  { $matchDir    = $_.Path     -eq $dirFilter }

            $matchSearch -and $matchAction -and $matchProto -and $matchDir
        }

        $dgFWLogs.ItemsSource = $filtered
        $txtFWLogCount.Text = "Showing $($filtered.Count) of $($script:OriginalFWLogData.Count) log entries"
    }

    $txtFWLogSearch.Add_TextChanged($ApplyFWLogFilters)
    $cmbFWLogAction.Add_SelectionChanged($ApplyFWLogFilters)
    $cmbFWLogProtocol.Add_SelectionChanged($ApplyFWLogFilters)
    $cmbFWLogDirection.Add_SelectionChanged($ApplyFWLogFilters)

    $fwLogWindow.ShowDialog() | Out-Null
}

Function Show-ASRWindow {
    param(
        [Parameter(Mandatory=$true)]$ASRData
    )
    
    $asrXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ASR Rules Status" Height="600" Width="900" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="400" MinWidth="900" MaxWidth="900">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="Attack Surface Reduction Rules" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtASRCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>
        
        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Filter by Status:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbStatus" Width="150" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Enabled"/>
                    <ComboBoxItem Content="Audit"/>
                    <ComboBoxItem Content="Warning"/>
                    <ComboBoxItem Content="Not Enabled"/>
                </ComboBox>
            </StackPanel>
        </Border>
        
        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgASR" AutoGenerateColumns="False" IsReadOnly="True" 
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ASR Rule" Binding="{Binding ASR}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextWrapping" Value="Wrap"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="120">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="FontWeight" Value="SemiBold"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

    $asrReader = (New-Object System.Xml.XmlNodeReader ([xml]$asrXaml))
    $asrWindow = [Windows.Markup.XamlReader]::Load($asrReader)
    
    # Get controls
    $dgASR = $asrWindow.FindName("dgASR")
    $cmbStatus = $asrWindow.FindName("cmbStatus")
    $txtASRCount = $asrWindow.FindName("txtASRCount")
    
    # Store original data
    $script:OriginalASRData = $ASRData
    
    # Set initial data
    $dgASR.ItemsSource = $ASRData
    $txtASRCount.Text = "Showing $($ASRData.Count) ASR rules"
    
    # Filter by status
    $cmbStatus.Add_SelectionChanged({
        $statusFilter = $cmbStatus.SelectedItem.Content
        
        if ($statusFilter -eq "All") {
            $dgASR.ItemsSource = $script:OriginalASRData
            $txtASRCount.Text = "Showing $($script:OriginalASRData.Count) ASR rules"
        } else {
            $filtered = $script:OriginalASRData | Where-Object { $_.Status -eq $statusFilter }
            $dgASR.ItemsSource = $filtered
            $txtASRCount.Text = "Showing $($filtered.Count) of $($script:OriginalASRData.Count) ASR rules"
        }
    })
    
    $asrWindow.ShowDialog() | Out-Null
}

Function Show-ASRExclusionsWindow {
    param(
        [Parameter(Mandatory=$true)]$ExclusionData
    )

    $asrExclXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ASR Per-Rule Exclusions" Height="600" Width="900" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="400" MinWidth="900" MaxWidth="900">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="ASR Per-Rule Exclusions" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtASRExclCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Filter by Rule:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbASRExclRule" Width="400" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                </ComboBox>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgASRExcl" AutoGenerateColumns="False" IsReadOnly="True"
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ASR Rule" Binding="{Binding Rule}" Width="350">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextWrapping" Value="Wrap"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Exclusion" Binding="{Binding Exclusion}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextWrapping" Value="Wrap"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

    $asrExclReader = (New-Object System.Xml.XmlNodeReader ([xml]$asrExclXaml))
    $asrExclWindow = [Windows.Markup.XamlReader]::Load($asrExclReader)

    $dgASRExcl = $asrExclWindow.FindName("dgASRExcl")
    $cmbASRExclRule = $asrExclWindow.FindName("cmbASRExclRule")
    $txtASRExclCount = $asrExclWindow.FindName("txtASRExclCount")

    $script:OriginalASRExclData = $ExclusionData

    # Populate filter combo with unique rule names
    $uniqueRules = $ExclusionData | Select-Object -ExpandProperty Rule -Unique | Sort-Object
    foreach ($rule in $uniqueRules) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $rule
        $cmbASRExclRule.Items.Add($item) | Out-Null
    }

    $dgASRExcl.ItemsSource = $ExclusionData
    $txtASRExclCount.Text = "Showing $($ExclusionData.Count) exclusions"

    $cmbASRExclRule.Add_SelectionChanged({
        $ruleFilter = $cmbASRExclRule.SelectedItem.Content

        if ($ruleFilter -eq "All") {
            $dgASRExcl.ItemsSource = $script:OriginalASRExclData
            $txtASRExclCount.Text = "Showing $($script:OriginalASRExclData.Count) exclusions"
        } else {
            $filtered = $script:OriginalASRExclData | Where-Object { $_.Rule -eq $ruleFilter }
            $dgASRExcl.ItemsSource = $filtered
            $txtASRExclCount.Text = "Showing $($filtered.Count) of $($script:OriginalASRExclData.Count) exclusions"
        }
    })

    $asrExclWindow.ShowDialog() | Out-Null
}

Function Show-ExclusionsWindow {
    param(
        [Parameter(Mandatory=$true)]$ExclusionData
    )
    
    $exclXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Defender AV Exclusions" Height="600" Width="800" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="400" MinWidth="800" MaxWidth="800">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="Defender AV Exclusions" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtExclCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>
        
        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Filter by Type:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbType" Width="150" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Path"/>
                    <ComboBoxItem Content="Extension"/>
                    <ComboBoxItem Content="Process"/>
                    <ComboBoxItem Content="IP Address"/>
                </ComboBox>
                <Separator Margin="15,0"/>
                <Label Content="Search:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBox Name="txtSearch" Width="200" Margin="5,0" Padding="5" FontFamily="Segoe UI" VerticalContentAlignment="Center"/>
            </StackPanel>
        </Border>
        
        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgExclusions" AutoGenerateColumns="False" IsReadOnly="True" 
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Type" Binding="{Binding Type}" Width="100">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="FontWeight" Value="SemiBold"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Value" Binding="{Binding Value}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

    $exclReader = (New-Object System.Xml.XmlNodeReader ([xml]$exclXaml))
    $exclWindow = [Windows.Markup.XamlReader]::Load($exclReader)
    
    # Get controls
    $dgExclusions = $exclWindow.FindName("dgExclusions")
    $cmbType = $exclWindow.FindName("cmbType")
    $txtSearch = $exclWindow.FindName("txtSearch")
    $txtExclCount = $exclWindow.FindName("txtExclCount")
    
    # Store original data
    $script:OriginalExclData = $ExclusionData
    
    # Set initial data
    $dgExclusions.ItemsSource = $ExclusionData
    $txtExclCount.Text = "Showing $($ExclusionData.Count) exclusions"
    
    # Filter function
    $ApplyExclFilters = {
        $typeFilter = $cmbType.SelectedItem.Content
        $searchText = $txtSearch.Text.ToLower()
        
        $filtered = $script:OriginalExclData | Where-Object {
            $matchesType = $true
            $matchesSearch = $true
            
            if ($typeFilter -ne "All") {
                $matchesType = $_.Type -eq $typeFilter
            }
            
            if ($searchText) {
                $matchesSearch = $_.Value -like "*$searchText*"
            }
            
            $matchesType -and $matchesSearch
        }
        
        $dgExclusions.ItemsSource = $filtered
        $txtExclCount.Text = "Showing $($filtered.Count) of $($script:OriginalExclData.Count) exclusions"
    }
    
    $cmbType.Add_SelectionChanged($ApplyExclFilters)
    
    $txtSearch.Add_TextChanged($ApplyExclFilters)
    
    $exclWindow.ShowDialog() | Out-Null
}

Function Show-LogWindow {
    param(
        [Parameter(Mandatory=$true)]$LogData,
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$LogType
    )
    
    $logXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$Title" Height="750" Width="1200" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1200" MaxWidth="1200">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="$Title" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtLogCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>
        
        <!-- Filter Section -->
        <Border Grid.Row="1" Background="White" Padding="10" Margin="0,0,0,10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1">
            <StackPanel Orientation="Horizontal">
                <Label Content="Filter:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBox Name="txtFilter" Width="300" Margin="5,0" Padding="5" FontFamily="Segoe UI" VerticalContentAlignment="Center"/>
                <Button Name="btnApplyFilter" Content="Apply" Padding="15,5" Margin="5,0" Background="#2D2D44" Foreground="White" BorderBrush="#2D2D44" FontFamily="Segoe UI" Cursor="Hand"/>
                <Button Name="btnClearFilter" Content="Clear" Padding="15,5" Margin="5,0" Background="#E0E0E0" BorderBrush="#999" FontFamily="Segoe UI" Cursor="Hand"/>
                <Separator Margin="10,0"/>
                <Label Content="Level:" FontWeight="Bold" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                <ComboBox Name="cmbLevel" Width="120" Margin="5,0" Padding="5" FontFamily="Segoe UI" SelectedIndex="0">
                    <ComboBoxItem Content="All"/>
                    <ComboBoxItem Content="Information"/>
                    <ComboBoxItem Content="Warning"/>
                    <ComboBoxItem Content="Error"/>
                </ComboBox>
            </StackPanel>
        </Border>
        
        <!-- DataGrid -->
        <DataGrid Grid.Row="2" Name="dgLogs" AutoGenerateColumns="False" IsReadOnly="True" 
                  CanUserSortColumns="True" CanUserReorderColumns="True" CanUserResizeColumns="True"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#F9F9F9"
                  BorderBrush="#CCC" BorderThickness="1" FontFamily="Segoe UI">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Time" Binding="{Binding TimeCreated}" Width="160">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="ID" Binding="{Binding Id}" Width="60">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Level" Binding="{Binding LevelDisplayName}" Width="90">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Message" Binding="{Binding Message}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Padding" Value="5"/>
                            <Setter Property="TextWrapping" Value="NoWrap"/>
                            <Setter Property="TextTrimming" Value="CharacterEllipsis"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
        
        <!-- Details Section -->
        <GridSplitter Grid.Row="3" Height="5" HorizontalAlignment="Stretch" Background="#E0E0E0" Margin="0,5"/>
        
        <Border Grid.Row="4" Background="White" Padding="10" CornerRadius="5" BorderBrush="#CCC" BorderThickness="1" Height="150">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Label Grid.Row="0" Content="Message Details:" FontWeight="Bold" FontFamily="Segoe UI"/>
                <TextBox Grid.Row="1" Name="txtDetails" IsReadOnly="True" TextWrapping="Wrap" 
                         VerticalScrollBarVisibility="Auto" BorderBrush="#CCC" Padding="5" FontFamily="Segoe UI"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $logReader = (New-Object System.Xml.XmlNodeReader ([xml]$logXaml))
    $logWindow = [Windows.Markup.XamlReader]::Load($logReader)
    
    # Get controls
    $dgLogs = $logWindow.FindName("dgLogs")
    $txtFilter = $logWindow.FindName("txtFilter")
    $btnApplyFilter = $logWindow.FindName("btnApplyFilter")
    $btnClearFilter = $logWindow.FindName("btnClearFilter")
    $cmbLevel = $logWindow.FindName("cmbLevel")
    $txtDetails = $logWindow.FindName("txtDetails")
    $txtLogCount = $logWindow.FindName("txtLogCount")
    
    # Store original data
    $script:OriginalLogData = $LogData
    $script:FilteredLogData = $LogData
    
    # Set initial data
    $dgLogs.ItemsSource = $LogData
    $txtLogCount.Text = "Showing $($LogData.Count) log entries"
    
    # Filter function
    $ApplyFilters = {
        $filterText = $txtFilter.Text.ToLower()
        $levelFilter = $cmbLevel.SelectedItem.Content
        
        $script:FilteredLogData = $script:OriginalLogData | Where-Object {
            $matchesText = $true
            $matchesLevel = $true
            
            if ($filterText) {
                $matchesText = ($_.Message -like "*$filterText*") -or ($_.Id -like "*$filterText*")
            }
            
            if ($levelFilter -ne "All") {
                $matchesLevel = $_.LevelDisplayName -eq $levelFilter
            }
            
            $matchesText -and $matchesLevel
        }
        
        $dgLogs.ItemsSource = $script:FilteredLogData
        $txtLogCount.Text = "Showing $($script:FilteredLogData.Count) of $($script:OriginalLogData.Count) log entries"
    }
    
    # Event handlers
    $btnApplyFilter.Add_Click($ApplyFilters)
    
    $btnClearFilter.Add_Click({
        $txtFilter.Text = ""
        $cmbLevel.SelectedIndex = 0
        $dgLogs.ItemsSource = $script:OriginalLogData
        $txtLogCount.Text = "Showing $($script:OriginalLogData.Count) log entries"
    })
    
    $cmbLevel.Add_SelectionChanged($ApplyFilters)
    
    $txtFilter.Add_KeyDown({
        param($sender, $e)
        if ($e.Key -eq "Return") {
            $ApplyFilters.Invoke()
        }
    })
    
    # Show details when row is selected
    $dgLogs.Add_SelectionChanged({
        if ($dgLogs.SelectedItem) {
            $selectedLog = $dgLogs.SelectedItem
            $txtDetails.Text = "Time: $($selectedLog.TimeCreated)`r`nEvent ID: $($selectedLog.Id)`r`nLevel: $($selectedLog.LevelDisplayName)`r`n`r`nMessage:`r`n$($selectedLog.Message)"
        }
    })
    
    $logWindow.ShowDialog() | Out-Null
}

# ==================== EVENT HANDLERS ====================

$MainWindow1.Add_Loaded({ 
    try {
        WindowLoader
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
})

$btnDownloadClientAnalyzer.Add_Click({ 
    try {
        $folder = (New-Object -ComObject Shell.Application).BrowseForFolder(0, "Select Destination Folder", 0).Self.Path
        if ($folder) {
            $url = "https://aka.ms/mdatpanalyzer"
            $destination = Join-Path -Path $folder -ChildPath "MDEClientAnalyzer.zip"
            Invoke-WebRequest -Uri $url -OutFile $destination
            [System.Windows.MessageBox]::Show("File downloaded to $destination", 'Download Complete', 'OK', 'Information')
        } else {
            [System.Windows.MessageBox]::Show("No folder selected. Download canceled.", 'Canceled', 'OK', 'Warning')
        }
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
})

$btnUpdateIntel.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $arg = " -SignatureUpdate"
        Start-Process "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList $arg -Wait
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show("Signature update complete!", 'Update', 'OK', 'Information')
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
})

$btnShowSenseLogs.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $SenseLogs = Get-WinEvent -LogName "Microsoft-Windows-SENSE/Operational" -ErrorAction Stop | 
            Select-Object TimeCreated, Id, LevelDisplayName, Message
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        Show-LogWindow -LogData $SenseLogs -Title "SENSE Logs" -LogType "SENSE"
    }
    catch { 
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error') 
    }
})

$btnShowASR.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $GetASRRuleStatus = GetASRRuleStatus
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow

        if ($GetASRRuleStatus -eq "ASR rules empty") {
            [System.Windows.MessageBox]::Show("No ASR rules configured on this system.", 'ASR Rules', 'OK', 'Information')
        } else {
            Show-ASRWindow -ASRData $GetASRRuleStatus
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnShowASRExclusions.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $asrExclusions = GetASRPerRuleExclusions
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow

        if ($asrExclusions -eq "No per-rule ASR exclusions found") {
            [System.Windows.MessageBox]::Show("No per-rule ASR exclusions found in the registry.", 'ASR Exclusions', 'OK', 'Information')
        } else {
            Show-ASRExclusionsWindow -ExclusionData $asrExclusions
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnOpenExploitProtectionXML.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        # Check if exploit protection XML exists in common locations
        $possiblePaths = @(
            "$env:ProgramData\Microsoft\Windows Defender\Platform\*\EpManifest.xml",
            "$env:TEMP\ExploitProtection.xml"
        )

        $xmlPath = $null
        foreach ($path in $possiblePaths) {
            $resolved = Resolve-Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($resolved) {
                $xmlPath = $resolved.Path
                break
            }
        }

        # If not found, export it to temp location
        if (-not $xmlPath) {
            $xmlPath = "$env:TEMP\ExploitProtection.xml"
            Get-ProcessMitigation -RegistryConfigFilePath $xmlPath -ErrorAction Stop
        }

        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow

        # Open the XML file with default application (usually Notepad or default XML editor)
        if (Test-Path $xmlPath) {
            Start-Process $xmlPath
        } else {
            [System.Windows.MessageBox]::Show("Unable to locate or export Exploit Protection XML file.", 'Exploit Protection', 'OK', 'Warning')
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show("Error: $($Error[0].Exception.Message)", 'Error', 'OK', 'Error')
    }
})

$btnCheckForLastestUpdate.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $ReturnGetPlatformVersionAndEngine = GetPlatformVersionAndEngine
        $lblLastestEngineVersion_txt.Content = $ReturnGetPlatformVersionAndEngine[0]
        $lblLastestPlatformVersion_txt.Content = $ReturnGetPlatformVersionAndEngine[1]
        $lblLatestSigVersion_txt.Content = GetSignatureVersion
        $lblLastestEngineVersion_txt.Foreground = "#FF000000"
        $lblLastestPlatformVersion_txt.Foreground = "#FF000000"
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
    catch { [System.Windows.MessageBox]::Show($Error[0], 'Confirm', 'OK', 'Error') }
})

$btnShowDefenderAVLogs.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $DefenderLogs = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 50 -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        Show-LogWindow -LogData $DefenderLogs -Title "Defender AV Logs" -LogType "Defender"
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnExportASRBlockEvents.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $xmlQuery = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Windows Defender/Operational">
    <Select Path="Microsoft-Windows-Windows Defender/Operational">*[System[(EventID=1121 or EventID=1122 or EventID=5007)]]</Select>
    <Select Path="Microsoft-Windows-Windows Defender/WHC">*[System[(EventID=1121 or EventID=1122 or EventID=5007)]]</Select>
  </Query>
</QueryList>
"@
        $logs = Get-WinEvent -FilterXml $xmlQuery -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($logs.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No ASR Block events (1121/1122/5007) found.", 'ASR Block Events', 'OK', 'Information')
        } else {
            Show-LogWindow -LogData $logs -Title "ASR Block Events (1121/1122/5007)" -LogType "Defender"
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnExportASRAuditEvents.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $xmlQuery = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Windows Defender/Operational">
    <Select Path="Microsoft-Windows-Windows Defender/Operational">*[System[(EventID=1123 or EventID=1124 or EventID=5007)]]</Select>
    <Select Path="Microsoft-Windows-Windows Defender/WHC">*[System[(EventID=1123 or EventID=1124 or EventID=5007)]]</Select>
  </Query>
</QueryList>
"@
        $logs = Get-WinEvent -FilterXml $xmlQuery -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($logs.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No Controlled Folder Access events (1123/1124/5007) found.", 'Controlled Folder Access', 'OK', 'Information')
        } else {
            Show-LogWindow -LogData $logs -Title "Controlled Folder Access Events (1123/1124/5007)" -LogType "Defender"
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnExportExploitGuardEvents.Add_Click({
    try {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
        $xmlQuery = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Security-Mitigations/KernelMode">
    <Select Path="Microsoft-Windows-Security-Mitigations/KernelMode">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Concurrency">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Contention">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Messages">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Operational">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Power">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Render">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/Tracing">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Win32k/UIPI">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
    <Select Path="Microsoft-Windows-Security-Mitigations/UserMode">*[System[Provider[@Name='Microsoft-Windows-Security-Mitigations' or @Name='Microsoft-Windows-WER-Diag' or @Name='Microsoft-Windows-Win32k' or @Name='Win32k'] and ( (EventID &gt;= 1 and EventID &lt;= 24) or EventID=5 or EventID=260)]]</Select>
  </Query>
</QueryList>
"@
        $logs = Get-WinEvent -FilterXml $xmlQuery -Oldest -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        if ($logs.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No Exploit Guard protection events found.", 'Exploit Guard Events', 'OK', 'Information')
        } else {
            Show-LogWindow -LogData $logs -Title "Exploit Guard Protection Events" -LogType "Defender"
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnShowPerformanceReport.Add_Click({
    try {
        # Ask user if they want to open the recent report or a custom one
        $result = [System.Windows.MessageBox]::Show(
            "Do you want to open the recently recorded report?`n`nClick 'Yes' to open the recent report from this session.`nClick 'No' to browse for a custom ETL file.",
            'Select Report Source',
            'YesNoCancel',
            'Question'
        )

        $etlPath = $null

        if ($result -eq 'Yes') {
            # Use the recently recorded report
            $etlPath = "$WorkingPath\MDAV_Recording.etl"
            if (-not (Test-Path $etlPath)) {
                [System.Windows.MessageBox]::Show("No recent performance recording found. Please run 'Run Performance Analyzer' first or select a custom report.", 'Report Not Found', 'OK', 'Warning')
                return
            }
        }
        elseif ($result -eq 'No') {
            # Open file dialog to browse for custom ETL file
            Add-Type -AssemblyName System.Windows.Forms
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.InitialDirectory = $WorkingPath
            $openFileDialog.Filter = "ETL Files (*.etl)|*.etl|All Files (*.*)|*.*"
            $openFileDialog.Title = "Select Performance Report ETL File"

            if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $etlPath = $openFileDialog.FileName
            } else {
                return
            }
        }
        else {
            # User clicked Cancel
            return
        }

        # Process the selected ETL file
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait

        if (Test-Path $etlPath) {
            $PerformanceReport = Get-MpPerformanceReport -Path $etlPath -TopFiles:10 -TopExtensions:10 -TopProcesses:10 -TopScans:10 -Overview

            if ($PerformanceReport) {
                # Collect all selected reports to open
                $reportsToOpen = @()
                $missingReports = @()

                if ($rdbOverview.IsChecked -eq $true) {
                    if ($PerformanceReport.Overview) {
                        # Process Overview data to convert PerfHints array to readable text
                        $processedOverview = $PerformanceReport.Overview | Select-Object *, @{
                            Name = 'PerfHintsText'
                            Expression = {
                                if ($_.PerfHints) {
                                    ($_.PerfHints | ForEach-Object { $_.ToString() }) -join '; '
                                } else {
                                    'None'
                                }
                            }
                        } | Select-Object * -ExcludeProperty PerfHints

                        $reportsToOpen += @{Data = $processedOverview; Title = "Performance Report - Overview"}
                    } else {
                        $missingReports += "Overview"
                    }
                }

                if ($rdbTopfiles.IsChecked -eq $true) {
                    if ($PerformanceReport.TopFiles) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopFiles; Title = "Performance Report - Top Files Scans"}
                    } else {
                        $missingReports += "Top Files"
                    }
                }

                if ($rdbTopExtensions.IsChecked -eq $true) {
                    if ($PerformanceReport.TopExtensions) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopExtensions; Title = "Performance Report - Top Extensions Scans"}
                    } else {
                        $missingReports += "Top Extensions"
                    }
                }

                if ($rdbTopProcess.IsChecked -eq $true) {
                    if ($PerformanceReport.TopProcesses) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopProcesses; Title = "Performance Report - Top Processes Scans"}
                    } else {
                        $missingReports += "Top Processes"
                    }
                }

                if ($rdbTopScans.IsChecked -eq $true) {
                    if ($PerformanceReport.TopScans) {
                        $reportsToOpen += @{Data = $PerformanceReport.TopScans; Title = "Performance Report - Top Scans"}
                    } else {
                        $missingReports += "Top Scans"
                    }
                }

                # Open all windows using runspaces to display them simultaneously
                foreach ($report in $reportsToOpen) {
                    $runspace = [runspacefactory]::CreateRunspace()
                    $runspace.ApartmentState = "STA"
                    $runspace.ThreadOptions = "ReuseThread"
                    $runspace.Open()

                    $powershell = [powershell]::Create()
                    $powershell.Runspace = $runspace

                    [void]$powershell.AddScript({
                        param($reportData, $reportTitle)

                        Add-Type -AssemblyName PresentationFramework

                        $perfXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$reportTitle" Height="700" Width="1200" WindowStartupLocation="CenterScreen" Background="#F5F5F5" ResizeMode="CanResizeWithGrip" MinHeight="500" MinWidth="1000">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#2D2D44" Padding="15,10" Margin="0,0,0,10" CornerRadius="5">
            <StackPanel>
                <TextBlock Text="$reportTitle" FontSize="18" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI"/>
                <TextBlock Name="txtPerfCount" Text="Loading..." FontSize="12" Foreground="#CCE5FF" FontFamily="Segoe UI"/>
            </StackPanel>
        </Border>

        <!-- DataGrid -->
        <DataGrid Grid.Row="1" Name="dgPerformance" AutoGenerateColumns="True" IsReadOnly="True" Background="White"
                  AlternatingRowBackground="#F9F9F9" GridLinesVisibility="Horizontal" HeadersVisibility="Column"
                  CanUserSortColumns="True" CanUserResizeColumns="True" CanUserReorderColumns="True"
                  HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
            <DataGrid.ColumnHeaderStyle>
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#2D2D44"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Padding" Value="10,5"/>
                    <Setter Property="BorderBrush" Value="#1A1A2E"/>
                    <Setter Property="BorderThickness" Value="0,0,1,0"/>
                </Style>
            </DataGrid.ColumnHeaderStyle>
            <DataGrid.RowStyle>
                <Style TargetType="DataGridRow">
                    <Setter Property="Height" Value="30"/>
                </Style>
            </DataGrid.RowStyle>
        </DataGrid>
    </Grid>
</Window>
"@

                        $perfReader = (New-Object System.Xml.XmlNodeReader ([xml]$perfXaml))
                        $perfWindow = [Windows.Markup.XamlReader]::Load($perfReader)

                        $dgPerformance = $perfWindow.FindName("dgPerformance")
                        $txtPerfCount = $perfWindow.FindName("txtPerfCount")

                        $dataArray = @()
                        if ($reportData -is [Array]) {
                            $dataArray = $reportData
                        } else {
                            $dataArray = @($reportData)
                        }

                        # Add event handler to enable text wrapping for PerfHintsText column
                        $dgPerformance.Add_AutoGeneratingColumn({
                            param($sender, $e)
                            if ($e.PropertyName -eq "PerfHintsText") {
                                $e.Column.Width = 400
                                $style = New-Object System.Windows.Style([System.Windows.Controls.TextBlock])
                                $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::TextWrappingProperty, [System.Windows.TextWrapping]::Wrap)))
                                $style.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.TextBlock]::PaddingProperty, (New-Object System.Windows.Thickness(5)))))
                                $e.Column.ElementStyle = $style
                            }
                        })

                        $dgPerformance.ItemsSource = $dataArray
                        $txtPerfCount.Text = "Showing $($dataArray.Count) items"

                        $perfWindow.ShowDialog() | Out-Null

                    }).AddArgument($report.Data).AddArgument($report.Title)

                    $powershell.BeginInvoke()
                    Start-Sleep -Milliseconds 200
                }

                # Show warning if any reports are missing
                if ($missingReports.Count -gt 0) {
                    [System.Windows.MessageBox]::Show("The following reports had no data: $($missingReports -join ', '). Please run the performance recording for a longer time!", 'Missing Data', 'OK', 'Warning')
                }
            } else {
                [System.Windows.MessageBox]::Show("Performance report is empty... please run again for a longer time!")
            }
        } else {
            [System.Windows.MessageBox]::Show("ETL file not found: $etlPath", 'File Not Found', 'OK', 'Error')
        }

        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnExclusions.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $MPpreference = Get-MpPreference
        $ExclusionList = @()
        
        # Add Path exclusions
        if ($MPpreference.ExclusionPath) {
            foreach ($path in $MPpreference.ExclusionPath) {
                $ExclusionList += [PSCustomObject]@{ Type = "Path"; Value = $path }
            }
        }
        
        # Add Extension exclusions
        if ($MPpreference.ExclusionExtension) {
            foreach ($ext in $MPpreference.ExclusionExtension) {
                $ExclusionList += [PSCustomObject]@{ Type = "Extension"; Value = $ext }
            }
        }
        
        # Add Process exclusions
        if ($MPpreference.ExclusionProcess) {
            foreach ($proc in $MPpreference.ExclusionProcess) {
                $ExclusionList += [PSCustomObject]@{ Type = "Process"; Value = $proc }
            }
        }
        
        # Add IP Address exclusions
        if ($MPpreference.ExclusionIpAddress) {
            foreach ($ip in $MPpreference.ExclusionIpAddress) {
                $ExclusionList += [PSCustomObject]@{ Type = "IP Address"; Value = $ip }
            }
        }
        
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        
        if ($ExclusionList.Count -gt 0) {
            Show-ExclusionsWindow -ExclusionData $ExclusionList
        } else {
            [System.Windows.MessageBox]::Show("No Defender AV exclusions found!", 'Exclusions', 'OK', 'Information')
        }
    }
    catch { 
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error') 
    }
})

$btnRunPerformance.Add_Click({
    PerformanceAnalyze
})

$btnShowEstimatedImpact.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        # Find the most recent MPlog file in the Support directory
        $supportPath = "C:\ProgramData\Microsoft\Windows Defender\Support"

        if (-not (Test-Path $supportPath)) {
            [System.Windows.MessageBox]::Show("Support directory not found: $supportPath", 'Directory Not Found', 'OK', 'Warning')
            $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
            return
        }

        $mplogFiles = Get-ChildItem -Path $supportPath -Filter "MPLog-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

        if ($mplogFiles.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No MPlog files found in $supportPath", 'No Files Found', 'OK', 'Warning')
            $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
            return
        }

        # Use the most recent MPlog file
        $mplogFile = $mplogFiles[0]

        # Read the file and filter lines containing "EstimatedImpact"
        $estimatedImpactLines = Get-Content -Path $mplogFile.FullName | Where-Object { $_ -match "EstimatedImpact" }

        if ($estimatedImpactLines.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No 'EstimatedImpact' entries found in $($mplogFile.Name)", 'No Data Found', 'OK', 'Information')
            $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
            return
        }

        # Parse the log lines into objects for better display
        $impactData = @()
        foreach ($line in $estimatedImpactLines) {
            $timestamp = "N/A"
            $message = $line
            $impactValue = 0
            $path = ""

            # Try to parse timestamp and message
            if ($line -match '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)\s+(.+)$') {
                $timestamp = $matches[1]
                $message = $matches[2]
            }

            # Try to extract EstimatedImpact value (e.g., EstimatedImpact: 123)
            if ($message -match 'EstimatedImpact[:\s]+(\d+)') {
                $impactValue = [int]$matches[1]
            }

            # Try to extract file path from the message
            if ($message -match 'Path:\s*([^,\s]+)') {
                $path = $matches[1]
            } elseif ($message -match '\\\\[^,\s]+') {
                $path = $matches[0]
            }

            $impactData += [PSCustomObject]@{
                EstimatedImpact = $impactValue
                Path = $path
                Timestamp = $timestamp
                FullMessage = $message
            }
        }

        # Sort by EstimatedImpact descending (highest first)
        $impactData = $impactData | Sort-Object -Property EstimatedImpact -Descending

        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        Show-EstimatedImpactWindow -ImpactData $impactData
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

$btnShowFirewallRules.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        # Get all rules first
        $Rules = Get-NetFirewallRule -ErrorAction Stop
        
        # Get all port filters and application filters in bulk
        $PortFilters = Get-NetFirewallPortFilter -All -ErrorAction SilentlyContinue
        $AppFilters = Get-NetFirewallApplicationFilter -All -ErrorAction SilentlyContinue
        
        # Create hashtables for fast lookup
        $PortFilterHash = @{}
        foreach ($pf in $PortFilters) {
            $PortFilterHash[$pf.InstanceID] = $pf
        }
        
        $AppFilterHash = @{}
        foreach ($af in $AppFilters) {
            $AppFilterHash[$af.InstanceID] = $af
        }
        
        # Build the results
        $FirewallRules = foreach ($rule in $Rules) {
            $portFilter = $PortFilterHash[$rule.InstanceID]
            $appFilter = $AppFilterHash[$rule.InstanceID]
            
            [PSCustomObject]@{
                DisplayName = $rule.DisplayName
                Enabled     = $rule.Enabled
                Direction   = $rule.Direction
                Action      = $rule.Action
                Profile     = $rule.Profile
                Protocol    = if ($portFilter) { $portFilter.Protocol } else { "Any" }
                LocalPort   = if ($portFilter -and $portFilter.LocalPort) { $portFilter.LocalPort -join ", " } else { "Any" }
                RemotePort  = if ($portFilter -and $portFilter.RemotePort) { $portFilter.RemotePort -join ", " } else { "Any" }
                Program     = if ($appFilter -and $appFilter.Program) { $appFilter.Program } else { "Any" }
            }
        }
        
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        
        if ($FirewallRules) {
            Show-FirewallRulesWindow -RulesData $FirewallRules
        } else {
            [System.Windows.MessageBox]::Show("No firewall rules found.", 'Firewall Rules', 'OK', 'Information')
        }
    }
    catch { 
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error') 
    }
})

$btnShowFirewallLogs.Add_Click({
    $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $logPath = "C:\Windows\System32\LogFiles\Firewall\pfirewall.log"

        if (-not (Test-Path $logPath)) {
            $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
            [System.Windows.MessageBox]::Show(
                "Firewall log file not found at:`n$logPath`n`nTo enable firewall logging, open Windows Defender Firewall with Advanced Security > Properties > select a profile > Logging > Customize, then set 'Log dropped packets' and/or 'Log successful connections' to Yes.",
                'Firewall Logging Not Enabled', 'OK', 'Warning')
            return
        }

        # Read log file — skip comment lines starting with #
        $rawLines = Get-Content -Path $logPath -ErrorAction Stop | Where-Object { $_ -notmatch '^#' -and $_.Trim() -ne '' }

        if ($rawLines.Count -eq 0) {
            $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
            [System.Windows.MessageBox]::Show("Firewall log file exists but contains no entries yet. Make sure logging is enabled and some traffic has occurred.", 'No Log Entries', 'OK', 'Information')
            return
        }

        # Fields: date time action protocol src-ip dst-ip src-port dst-port size tcpflags tcpsyn tcpack tcpwin icmptype icmpcode info path
        $logData = foreach ($line in $rawLines) {
            $parts = $line -split ' '
            if ($parts.Count -ge 16) {
                [PSCustomObject]@{
                    DateTime = "$($parts[0]) $($parts[1])"
                    Action   = $parts[2]
                    Protocol = $parts[3]
                    SrcIP    = $parts[4]
                    DstIP    = $parts[5]
                    SrcPort  = $parts[6]
                    DstPort  = $parts[7]
                    Size     = $parts[8]
                    Info     = $parts[15]
                    Path     = if ($parts.Count -ge 17) { $parts[16] } else { "-" }
                }
            }
        }

        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow

        if ($logData) {
            Show-FirewallLogsWindow -LogData $logData
        } else {
            [System.Windows.MessageBox]::Show("Could not parse any entries from the firewall log.", 'Parse Error', 'OK', 'Warning')
        }
    }
    catch {
        $MainWindow1.Cursor = [System.Windows.Input.Cursors]::Arrow
        [System.Windows.MessageBox]::Show($Error[0], 'Error', 'OK', 'Error')
    }
})

# Show Form
$Form.ShowDialog() | Out-Null
