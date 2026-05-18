import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const nid = () => crypto.randomBytes(12).toString("hex").toUpperCase();

const swiftFiles = [
  "Baseline/App/BaselineApp.swift",
  "Baseline/App/RootView.swift",
  "Baseline/App/MainTabView.swift",
  "Baseline/App/AppAppearance.swift",
  "Baseline/Theme/Theme.swift",
  "Baseline/Auth/AuthManager.swift",
  "Baseline/Auth/LoginView.swift",
  "Baseline/Auth/SignUpView.swift",
  "Baseline/Onboarding/OnboardingFlow.swift",
  "Baseline/Onboarding/OnboardingViewModel.swift",
  "Baseline/Onboarding/OnboardingContentPage.swift",
  "Baseline/Onboarding/OnboardingScreen1.swift",
  "Baseline/Onboarding/OnboardingScreen2.swift",
  "Baseline/Onboarding/OnboardingScreen3.swift",
  "Baseline/Onboarding/OnboardingScreen4.swift",
  "Baseline/Onboarding/OnboardingSetupView.swift",
  "Baseline/Home/HomeView.swift",
  "Baseline/Home/StreakCardView.swift",
  "Baseline/Home/MountainProgressView.swift",
  "Baseline/Home/HomeViewModel.swift",
  "Baseline/CheckIn/CheckInFlow.swift",
  "Baseline/CheckIn/ReflectionQuestionBank.swift",
  "Baseline/CheckIn/GoalReviewView.swift",
  "Baseline/CheckIn/ReflectionView.swift",
  "Baseline/CheckIn/DayResultView.swift",
  "Baseline/CheckIn/CheckInViewModel.swift",
  "Baseline/Coach/CoachView.swift",
  "Baseline/Coach/CoachMessageView.swift",
  "Baseline/Coach/CoachViewModel.swift",
  "Baseline/Timers/TimersView.swift",
  "Baseline/Timers/TimerRunningView.swift",
  "Baseline/Timers/TimersViewModel.swift",
  "Baseline/Profile/ProfileView.swift",
  "Baseline/Profile/ProfileViewModel.swift",
  "Baseline/Gate/GateView.swift",
  "Baseline/Gate/GateViewModel.swift",
  "Baseline/MessageToSelf/MessageToSelfView.swift",
  "Baseline/MessageToSelf/MessageToSelfViewModel.swift",
  "Baseline/Shared/APIClient.swift",
  "Baseline/Shared/SupabaseClient.swift",
  "Baseline/Shared/Components/BaselineButton.swift",
  "Baseline/Shared/Components/GoalRowView.swift",
  "Baseline/Shared/Components/StreakBadgeView.swift",
  "Baseline/Models/Day.swift",
  "Baseline/Models/Goal.swift",
  "Baseline/Models/Streak.swift",
  "Baseline/Models/CheckIn.swift",
  "Baseline/Models/User.swift",
];

const I = Object.fromEntries(
  [
    "PROJECT",
    "TARGET",
    "MAIN_GROUP",
    "PRODUCT_GROUP",
    "APP_PRODUCT",
    "SOURCES_PHASE",
    "FRAMEWORKS_PHASE",
    "RESOURCES_PHASE",
    "CONFIG_LIST_PROJECT",
    "CONFIG_LIST_TARGET",
    "DEBUG_PROJECT",
    "RELEASE_PROJECT",
    "DEBUG_TARGET",
    "RELEASE_TARGET",
    "PACKAGE_REF",
    "CONFIG_FILE",
    "ASSETS",
  ].map((k) => [k, nid()]),
);

const pkgProduct = nid();
const pkgBuild = nid();
const assetBuild = nid();
const fileRef = Object.fromEntries(swiftFiles.map((p) => [p, nid()]));
const buildSrc = Object.fromEntries(swiftFiles.map((p) => [p, nid()]));
const g = {
  app: nid(),
  theme: nid(),
  auth: nid(),
  onb: nid(),
  home: nid(),
  ci: nid(),
  coach: nid(),
  timers: nid(),
  profile: nid(),
  gate: nid(),
  mts: nid(),
  comp: nid(),
  shared: nid(),
  models: nid(),
  baseline: nid(),
};

const L = [];
const line = (s = "") => L.push(s);

line("// !$*UTF8*$!");
line("{");
line("\tarchiveVersion = 1;");
line("\tclasses = {};");
line("\tobjectVersion = 56;");
line("\tobjects = {");

line("\t\t/* Begin PBXBuildFile section */");
for (const p of swiftFiles) {
  const n = path.basename(p);
  line(`\t\t${buildSrc[p]} /* ${n} in Sources */ = {isa = PBXBuildFile; fileRef = ${fileRef[p]} /* ${n} */; };`);
}
line(`\t\t${pkgBuild} /* Supabase in Frameworks */ = {isa = PBXBuildFile; productRef = ${pkgProduct} /* Supabase */; };`);
line(`\t\t${assetBuild} /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = ${I.ASSETS} /* Assets.xcassets */; };`);
line("\t\t/* End PBXBuildFile section */");
line("");

line("\t\t/* Begin PBXFileReference section */");
line(
  `\t\t${I.APP_PRODUCT} /* Baseline.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Baseline.app; sourceTree = BUILT_PRODUCTS_DIR; };`,
);
for (const p of swiftFiles) {
  const n = path.basename(p);
  line(`\t\t${fileRef[p]} /* ${n} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${n}; sourceTree = "<group>"; };`);
}
line(
  `\t\t${I.ASSETS} /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };`,
);
line(
  `\t\t${I.CONFIG_FILE} /* Config.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Config/Config.xcconfig; sourceTree = SOURCE_ROOT; };`,
);
line("\t\t/* End PBXFileReference section */");
line("");

line("\t\t/* Begin PBXFrameworksBuildPhase section */");
line(`\t\t${I.FRAMEWORKS_PHASE} /* Frameworks */ = {`);
line("\t\t\tisa = PBXFrameworksBuildPhase;");
line("\t\t\tbuildActionMask = 2147483647;");
line("\t\t\tfiles = (");
line(`\t\t\t\t${pkgBuild} /* Supabase in Frameworks */,`);
line("\t\t\t);");
line("\t\t\trunOnlyForDeploymentPostprocessing = 0;");
line("\t\t};");
line("\t\t/* End PBXFrameworksBuildPhase section */");
line("");

const grp = (id, name, pth, children) =>
  `\t\t${id} /* ${name} */ = {isa = PBXGroup; children = (${children.join(", ")}); path = ${pth}; sourceTree = "<group>"; };`;

line("\t\t/* Begin PBXGroup section */");
line(
  grp(g.app, "App", "App", [
    `${fileRef["Baseline/App/BaselineApp.swift"]} /* BaselineApp.swift */`,
    `${fileRef["Baseline/App/RootView.swift"]} /* RootView.swift */`,
    `${fileRef["Baseline/App/MainTabView.swift"]} /* MainTabView.swift */`,
    `${fileRef["Baseline/App/AppAppearance.swift"]} /* AppAppearance.swift */`,
  ]),
);
line(grp(g.theme, "Theme", "Theme", [`${fileRef["Baseline/Theme/Theme.swift"]} /* Theme.swift */`]));
line(
  grp(g.auth, "Auth", "Auth", [
    `${fileRef["Baseline/Auth/AuthManager.swift"]} /* AuthManager.swift */`,
    `${fileRef["Baseline/Auth/LoginView.swift"]} /* LoginView.swift */`,
    `${fileRef["Baseline/Auth/SignUpView.swift"]} /* SignUpView.swift */`,
  ]),
);
line(
  grp(g.onb, "Onboarding", "Onboarding", [
    `${fileRef["Baseline/Onboarding/OnboardingFlow.swift"]} /* OnboardingFlow.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingViewModel.swift"]} /* OnboardingViewModel.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingContentPage.swift"]} /* OnboardingContentPage.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingScreen1.swift"]} /* OnboardingScreen1.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingScreen2.swift"]} /* OnboardingScreen2.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingScreen3.swift"]} /* OnboardingScreen3.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingScreen4.swift"]} /* OnboardingScreen4.swift */`,
    `${fileRef["Baseline/Onboarding/OnboardingSetupView.swift"]} /* OnboardingSetupView.swift */`,
  ]),
);
line(
  grp(g.home, "Home", "Home", [
    `${fileRef["Baseline/Home/HomeView.swift"]} /* HomeView.swift */`,
    `${fileRef["Baseline/Home/StreakCardView.swift"]} /* StreakCardView.swift */`,
    `${fileRef["Baseline/Home/MountainProgressView.swift"]} /* MountainProgressView.swift */`,
    `${fileRef["Baseline/Home/HomeViewModel.swift"]} /* HomeViewModel.swift */`,
  ]),
);
line(
  grp(g.ci, "CheckIn", "CheckIn", [
    `${fileRef["Baseline/CheckIn/CheckInFlow.swift"]} /* CheckInFlow.swift */`,
    `${fileRef["Baseline/CheckIn/ReflectionQuestionBank.swift"]} /* ReflectionQuestionBank.swift */`,
    `${fileRef["Baseline/CheckIn/GoalReviewView.swift"]} /* GoalReviewView.swift */`,
    `${fileRef["Baseline/CheckIn/ReflectionView.swift"]} /* ReflectionView.swift */`,
    `${fileRef["Baseline/CheckIn/DayResultView.swift"]} /* DayResultView.swift */`,
    `${fileRef["Baseline/CheckIn/CheckInViewModel.swift"]} /* CheckInViewModel.swift */`,
  ]),
);
line(
  grp(g.coach, "Coach", "Coach", [
    `${fileRef["Baseline/Coach/CoachView.swift"]} /* CoachView.swift */`,
    `${fileRef["Baseline/Coach/CoachMessageView.swift"]} /* CoachMessageView.swift */`,
    `${fileRef["Baseline/Coach/CoachViewModel.swift"]} /* CoachViewModel.swift */`,
  ]),
);
line(
  grp(g.timers, "Timers", "Timers", [
    `${fileRef["Baseline/Timers/TimersView.swift"]} /* TimersView.swift */`,
    `${fileRef["Baseline/Timers/TimerRunningView.swift"]} /* TimerRunningView.swift */`,
    `${fileRef["Baseline/Timers/TimersViewModel.swift"]} /* TimersViewModel.swift */`,
  ]),
);
line(
  grp(g.profile, "Profile", "Profile", [
    `${fileRef["Baseline/Profile/ProfileView.swift"]} /* ProfileView.swift */`,
    `${fileRef["Baseline/Profile/ProfileViewModel.swift"]} /* ProfileViewModel.swift */`,
  ]),
);
line(
  grp(g.gate, "Gate", "Gate", [
    `${fileRef["Baseline/Gate/GateView.swift"]} /* GateView.swift */`,
    `${fileRef["Baseline/Gate/GateViewModel.swift"]} /* GateViewModel.swift */`,
  ]),
);
line(
  grp(g.mts, "MessageToSelf", "MessageToSelf", [
    `${fileRef["Baseline/MessageToSelf/MessageToSelfView.swift"]} /* MessageToSelfView.swift */`,
    `${fileRef["Baseline/MessageToSelf/MessageToSelfViewModel.swift"]} /* MessageToSelfViewModel.swift */`,
  ]),
);
line(
  grp(g.comp, "Components", "Components", [
    `${fileRef["Baseline/Shared/Components/BaselineButton.swift"]} /* BaselineButton.swift */`,
    `${fileRef["Baseline/Shared/Components/GoalRowView.swift"]} /* GoalRowView.swift */`,
    `${fileRef["Baseline/Shared/Components/StreakBadgeView.swift"]} /* StreakBadgeView.swift */`,
  ]),
);
line(
  grp(g.shared, "Shared", "Shared", [
    `${fileRef["Baseline/Shared/APIClient.swift"]} /* APIClient.swift */`,
    `${fileRef["Baseline/Shared/SupabaseClient.swift"]} /* SupabaseClient.swift */`,
    `${g.comp} /* Components */`,
  ]),
);
line(
  grp(g.models, "Models", "Models", [
    `${fileRef["Baseline/Models/Day.swift"]} /* Day.swift */`,
    `${fileRef["Baseline/Models/Goal.swift"]} /* Goal.swift */`,
    `${fileRef["Baseline/Models/Streak.swift"]} /* Streak.swift */`,
    `${fileRef["Baseline/Models/CheckIn.swift"]} /* CheckIn.swift */`,
    `${fileRef["Baseline/Models/User.swift"]} /* User.swift */`,
  ]),
);
line(
  grp(g.baseline, "Baseline", "Baseline", [
    `${g.app} /* App */`,
    `${g.theme} /* Theme */`,
    `${g.auth} /* Auth */`,
    `${g.onb} /* Onboarding */`,
    `${g.home} /* Home */`,
    `${g.ci} /* CheckIn */`,
    `${g.coach} /* Coach */`,
    `${g.timers} /* Timers */`,
    `${g.profile} /* Profile */`,
    `${g.gate} /* Gate */`,
    `${g.mts} /* MessageToSelf */`,
    `${g.shared} /* Shared */`,
    `${g.models} /* Models */`,
    `${I.ASSETS} /* Assets.xcassets */`,
  ]),
);
line(
  `\t\t${I.PRODUCT_GROUP} /* Products */ = {isa = PBXGroup; children = (${I.APP_PRODUCT} /* Baseline.app */,); name = Products; sourceTree = "<group>"; };`,
);
line(
  `\t\t${I.MAIN_GROUP} = {isa = PBXGroup; children = (${g.baseline} /* Baseline */, ${I.PRODUCT_GROUP} /* Products */, ${I.CONFIG_FILE} /* Config.xcconfig */,); sourceTree = "<group>"; };`,
);
line("\t\t/* End PBXGroup section */");
line("");

line("\t\t/* Begin PBXNativeTarget section */");
line(`\t\t${I.TARGET} /* Baseline */ = {`);
line("\t\t\tisa = PBXNativeTarget;");
line(`\t\t\tbuildConfigurationList = ${I.CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "Baseline" */;`);
line("\t\t\tbuildPhases = (");
line(`\t\t\t\t${I.SOURCES_PHASE} /* Sources */,`);
line(`\t\t\t\t${I.FRAMEWORKS_PHASE} /* Frameworks */,`);
line(`\t\t\t\t${I.RESOURCES_PHASE} /* Resources */,`);
line("\t\t\t);");
line("\t\t\tbuildRules = ();");
line("\t\t\tdependencies = ();");
line("\t\t\tname = Baseline;");
line("\t\t\tpackageProductDependencies = (");
line(`\t\t\t\t${pkgProduct} /* Supabase */,`);
line("\t\t\t);");
line("\t\t\tproductName = Baseline;");
line(`\t\t\tproductReference = ${I.APP_PRODUCT} /* Baseline.app */;`);
line('\t\t\tproductType = "com.apple.product-type.application";');
line("\t\t};");
line("\t\t/* End PBXNativeTarget section */");
line("");

line("\t\t/* Begin PBXProject section */");
line(`\t\t${I.PROJECT} /* Project object */ = {`);
line("\t\t\tisa = PBXProject;");
line("\t\t\tattributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500;};");
line(`\t\t\tbuildConfigurationList = ${I.CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "Baseline" */;`);
line('\t\t\tcompatibilityVersion = "Xcode 14.0";');
line("\t\t\tdevelopmentRegion = en;");
line("\t\t\thasScannedForEncodings = 0;");
line("\t\t\tknownRegions = (en, Base,);");
line(`\t\t\tmainGroup = ${I.MAIN_GROUP};`);
line("\t\t\tpackageReferences = (");
line(`\t\t\t\t${I.PACKAGE_REF} /* XCRemoteSwiftPackageReference "supabase-swift" */,`);
line("\t\t\t);");
line(`\t\t\tproductRefGroup = ${I.PRODUCT_GROUP} /* Products */;`);
line('\t\t\tprojectDirPath = "";');
line('\t\t\tprojectRoot = "";');
line("\t\t\ttargets = (");
line(`\t\t\t\t${I.TARGET} /* Baseline */,`);
line("\t\t\t);");
line("\t\t};");
line("\t\t/* End PBXProject section */");
line("");

line("\t\t/* Begin PBXResourcesBuildPhase section */");
line(`\t\t${I.RESOURCES_PHASE} /* Resources */ = {`);
line("\t\t\tisa = PBXResourcesBuildPhase;");
line("\t\t\tbuildActionMask = 2147483647;");
line("\t\t\tfiles = (");
line(`\t\t\t\t${assetBuild} /* Assets.xcassets in Resources */,`);
line("\t\t\t);");
line("\t\t\trunOnlyForDeploymentPostprocessing = 0;");
line("\t\t};");
line("\t\t/* End PBXResourcesBuildPhase section */");
line("");

line("\t\t/* Begin PBXSourcesBuildPhase section */");
line(`\t\t${I.SOURCES_PHASE} /* Sources */ = {`);
line("\t\t\tisa = PBXSourcesBuildPhase;");
line("\t\t\tbuildActionMask = 2147483647;");
line("\t\t\tfiles = (");
for (const p of swiftFiles) {
  line(`\t\t\t\t${buildSrc[p]} /* ${path.basename(p)} in Sources */,`);
}
line("\t\t\t);");
line("\t\t\trunOnlyForDeploymentPostprocessing = 0;");
line("\t\t};");
line("\t\t/* End PBXSourcesBuildPhase section */");
line("");

line("\t\t/* Begin XCRemoteSwiftPackageReference section */");
line(`\t\t${I.PACKAGE_REF} /* XCRemoteSwiftPackageReference "supabase-swift" */ = {`);
line("\t\t\tisa = XCRemoteSwiftPackageReference;");
line('\t\t\trepositoryURL = "https://github.com/supabase/supabase-swift";');
line("\t\t\trequirement = {kind = upToNextMajorVersion; minimumVersion = 2.0.0;};");
line("\t\t};");
line("\t\t/* End XCRemoteSwiftPackageReference section */");
line("");

line("\t\t/* Begin XCSwiftPackageProductDependency section */");
line(`\t\t${pkgProduct} /* Supabase */ = {`);
line("\t\t\tisa = XCSwiftPackageProductDependency;");
line(`\t\t\tpackage = ${I.PACKAGE_REF} /* XCRemoteSwiftPackageReference "supabase-swift" */;`);
line('\t\t\tproductName = Supabase;');
line("\t\t};");
line("\t\t/* End XCSwiftPackageProductDependency section */");
line("");

const common = `				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_SUPABASE_ANON_KEY = $(SUPABASE_ANON_KEY);
				INFOPLIST_KEY_SUPABASE_URL = $(SUPABASE_URL);
				INFOPLIST_KEY_UIUserInterfaceStyle = Dark;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.resetbaseline.Baseline;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";`;

line("\t\t/* Begin XCBuildConfiguration section */");
line(
  `\t\t${I.DEBUG_PROJECT} /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 5.0;}; name = Debug;};`,
);
line(
  `\t\t${I.RELEASE_PROJECT} /* Release */ = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 5.0;}; name = Release;};`,
);
line(
  `\t\t${I.DEBUG_TARGET} /* Debug */ = {isa = XCBuildConfiguration; baseConfigurationReference = ${I.CONFIG_FILE} /* Config.xcconfig */; buildSettings = {\n${common}\n\t\t\t}; name = Debug;};`,
);
line(
  `\t\t${I.RELEASE_TARGET} /* Release */ = {isa = XCBuildConfiguration; baseConfigurationReference = ${I.CONFIG_FILE} /* Config.xcconfig */; buildSettings = {\n${common}\n\t\t\t}; name = Release;};`,
);
line("\t\t/* End XCBuildConfiguration section */");
line("");

line("\t\t/* Begin XCConfigurationList section */");
line(
  `\t\t${I.CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "Baseline" */ = {isa = XCConfigurationList; buildConfigurations = (${I.DEBUG_PROJECT} /* Debug */, ${I.RELEASE_PROJECT} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;};`,
);
line(
  `\t\t${I.CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "Baseline" */ = {isa = XCConfigurationList; buildConfigurations = (${I.DEBUG_TARGET} /* Debug */, ${I.RELEASE_TARGET} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;};`,
);
line("\t\t/* End XCConfigurationList section */");
line("\t};");
line(`\trootObject = ${I.PROJECT} /* Project object */;`);
line("}");

const projDir = path.join(__dirname, "..", "Baseline.xcodeproj");
fs.mkdirSync(projDir, { recursive: true });
fs.writeFileSync(path.join(projDir, "project.pbxproj"), L.join("\n") + "\n", "utf8");

const ws = path.join(projDir, "project.xcworkspace");
fs.mkdirSync(ws, { recursive: true });
fs.writeFileSync(
  path.join(ws, "contents.xcworkspacedata"),
  `<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "self:"></FileRef>
</Workspace>
`,
  "utf8",
);

const schemeDir = path.join(projDir, "xcshareddata", "xcschemes");
fs.mkdirSync(schemeDir, { recursive: true });
fs.writeFileSync(
  path.join(schemeDir, "Baseline.xcscheme"),
  `<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${I.TARGET}" BuildableName="Baseline.app" BlueprintName="Baseline" ReferencedContainer="container:Baseline.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"/>
   <LaunchAction buildConfiguration="Debug" launchStyle="0" useCustomWorkingDirectory="NO">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${I.TARGET}" BuildableName="Baseline.app" BlueprintName="Baseline" ReferencedContainer="container:Baseline.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release"/>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
`,
  "utf8",
);

const spm = path.join(ws, "xcshareddata", "swiftpm");
fs.mkdirSync(spm, { recursive: true });
const resolved = {
  pins: [
    {
      identity: "supabase-swift",
      kind: "remoteSourceControl",
      location: "https://github.com/supabase/supabase-swift",
      state: { revision: "dd29b624b9ceea87612d0b00457e1400f7d22c2e", version: "2.46.0" },
    },
  ],
  version: 3,
};
fs.writeFileSync(path.join(spm, "Package.resolved"), JSON.stringify(resolved, null, 2) + "\n", "utf8");
console.log("Wrote", path.join(projDir, "project.pbxproj"));
