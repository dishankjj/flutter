// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('iOS Workflow validation', () {
    MockIMobileDevice iMobileDevice;
    MockXcode xcode;
    MockProcessManager processManager;
    FileSystem fs;

    setUp(() {
      iMobileDevice = new MockIMobileDevice();
      xcode = new MockXcode();
      processManager = new MockProcessManager();
      fs = new MemoryFileSystem();
    });

    testUsingContext('Emit missing status when nothing is installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(
        hasPythonSixModule: false,
        hasHomebrew: false,
        hasIosDeploy: false,
      );
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when Xcode is not installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when Xcode is partially installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn('/Library/Developer/CommandLineTools');
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when Xcode version too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 7.0.1\nBuild version 7C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when Xcode EULA not signed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(false);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when python six not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(hasPythonSixModule: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when homebrew not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(hasHomebrew: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when libimobiledevice is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => new MockIMobileDevice(isWorking: false),
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when ios-deploy is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(hasIosDeploy: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when ios-deploy version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(iosDeployVersionText: '1.8.0');
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when CocoaPods is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(hasCocoaPods: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when CocoaPods version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget(cocoaPodsVersionText: '0.39.0');
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
    });

    testUsingContext('Emits partial status when CocoaPods is not initialized', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);

      final ValidationResult result = await new IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      ProcessManager: () => processManager,
    });

    testUsingContext('Succeeds when all checks pass', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);

      ensureDirectoryExists(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master', 'README.md'));

      final ValidationResult result = await new IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      ProcessManager: () => processManager,
    });
  });
}

final ProcessResult exitsHappy = new ProcessResult(
  1,     // pid
  0,     // exitCode
  '',    // stdout
  '',    // stderr
);

class MockIMobileDevice extends IMobileDevice {
  MockIMobileDevice({bool isWorking: true}) : isWorking = new Future<bool>.value(isWorking);

  @override
  final Future<bool> isWorking;
}

class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}

class IOSWorkflowTestTarget extends IOSWorkflow {
  IOSWorkflowTestTarget({
    this.hasPythonSixModule: true,
    this.hasHomebrew: true,
    bool hasIosDeploy: true,
    String iosDeployVersionText: '1.9.0',
    bool hasIDeviceInstaller: true,
    bool hasCocoaPods: true,
    String cocoaPodsVersionText: '1.2.0',
  }) : hasIosDeploy = new Future<bool>.value(hasIosDeploy),
       iosDeployVersionText = new Future<String>.value(iosDeployVersionText),
       hasIDeviceInstaller = new Future<bool>.value(hasIDeviceInstaller),
       hasCocoaPods = new Future<bool>.value(hasCocoaPods),
       cocoaPodsVersionText = new Future<String>.value(cocoaPodsVersionText);

  @override
  final bool hasPythonSixModule;

  @override
  final bool hasHomebrew;

  @override
  final Future<bool> hasIosDeploy;

  @override
  final Future<String> iosDeployVersionText;

  @override
  final Future<bool> hasIDeviceInstaller;

  @override
  final Future<bool> hasCocoaPods;

  @override
  final Future<String> cocoaPodsVersionText;
}
