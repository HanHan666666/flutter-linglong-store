// 特权 helper 纯逻辑单测（docs/47 §13.2）。
//
// 覆盖范围：协议请求校验（合法/非法/越权字段/字符集/长度）、事件编码、
// 白名单 argv 快照、串行状态机的 busy/notRunning/cancel/exited 迁移。
// 运行方式：build/scripts/test-privileged-helper.sh（cmake 开启
// LINGLONG_BUILD_HELPER_TESTS 后构建并执行本程序）。

#include <cstdio>
#include <string>
#include <vector>

#include "helper_protocol.h"
#include "helper_task_runner.h"

namespace {

int gFailures = 0;
int gChecks = 0;

void expectTrue(bool condition, const char* what) {
  ++gChecks;
  if (!condition) {
    ++gFailures;
    fprintf(stderr, "FAIL: %s\n", what);
  }
}

void expectEq(const std::string& actual, const std::string& expected,
              const char* what) {
  ++gChecks;
  if (actual != expected) {
    ++gFailures;
    fprintf(stderr, "FAIL: %s\n  expected: %s\n  actual:   %s\n", what,
            expected.c_str(), actual.c_str());
  }
}

void expectArgv(const std::vector<std::string>& actual,
                std::initializer_list<const char*> expected, const char* what) {
  ++gChecks;
  const std::vector<std::string> want(expected.begin(), expected.end());
  if (actual != want) {
    ++gFailures;
    std::string printed;
    for (const auto& item : actual) {
      printed += item + " ";
    }
    fprintf(stderr, "FAIL: %s\n  actual argv: %s\n", what, printed.c_str());
  }
}

bool parseOk(const std::string& line, helper::HelperRequest* out) {
  const helper::ParseResult result = helper::parseRequestLine(line);
  if (result.status != helper::ParseStatus::kOk) {
    return false;
  }
  *out = result.request;
  return true;
}

std::string parseFatalCode(const std::string& line) {
  const helper::ParseResult result = helper::parseRequestLine(line);
  if (result.status != helper::ParseStatus::kOk) {
    return result.errorCode;
  }
  return "";
}

// ---- 协议请求校验 ----

void testValidRequests() {
  helper::HelperRequest req;
  expectTrue(parseOk(
      R"({"v":1,"type":"start","requestId":"task-123","operation":"install","appId":"org.deepin.demo","version":"1.2.3","force":false})",
      &req),
             "valid install with version");
  expectTrue(req.type == helper::RequestType::kStart, "install type");
  expectTrue(req.operation == helper::HelperOperation::kInstall,
             "install operation");
  expectEq(req.appId, "org.deepin.demo", "install appId");
  expectEq(req.version, "1.2.3", "install version");
  expectTrue(!req.force, "install force=false");

  expectTrue(parseOk(
      R"({"v":1,"type":"start","requestId":"task-124","operation":"install","appId":"org.deepin.demo","force":true})",
      &req),
             "valid install without version, force=true");
  expectTrue(req.force, "install force=true");
  expectTrue(req.version.empty(), "install version omitted");

  expectTrue(parseOk(
      R"({"v":1,"type":"start","requestId":"task-125","operation":"update","appId":"org.deepin.demo"})",
      &req),
             "valid update");
  expectTrue(req.operation == helper::HelperOperation::kUpdate,
             "update operation");

  expectTrue(parseOk(R"({"v":1,"type":"cancel","requestId":"task-125"})", &req),
             "valid cancel");
  expectTrue(req.type == helper::RequestType::kCancel, "cancel type");

  expectTrue(parseOk(R"({"v":1,"type":"shutdown"})", &req), "valid shutdown");
  expectTrue(req.type == helper::RequestType::kShutdown, "shutdown type");
}

void testInvalidRequests() {
  expectEq(parseFatalCode("not-json"), helper::kErrorCodeInvalidRequest,
           "malformed JSON");
  expectEq(parseFatalCode(R"([])"), helper::kErrorCodeInvalidRequest,
           "non-object request");
  expectEq(parseFatalCode(R"({"type":"shutdown"})"),
           helper::kErrorCodeProtocolMismatch, "missing version");
  expectEq(parseFatalCode(R"({"v":"1","type":"shutdown"})"),
           helper::kErrorCodeProtocolMismatch, "string version");
  expectEq(parseFatalCode(R"({"v":2,"type":"shutdown"})"),
           helper::kErrorCodeProtocolMismatch, "future version");
  expectEq(parseFatalCode(R"({"v":1})"), helper::kErrorCodeInvalidRequest,
           "missing type");
  expectEq(parseFatalCode(R"({"v":1,"type":"remove","requestId":"x"})"),
           helper::kErrorCodeInvalidRequest, "unknown type");
  // 越权字段：客户端不得传 executable/argv/env/PID/路径（§6.2）。
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a.b","force":false,"argv":["x"]})"),
           helper::kErrorCodeInvalidRequest, "start with argv");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"shutdown","executable":"/bin/sh"})"),
           helper::kErrorCodeInvalidRequest, "shutdown with executable");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"update","appId":"a.b","version":"1"})"),
           helper::kErrorCodeInvalidRequest, "update with version");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"update","appId":"a.b","force":true})"),
           helper::kErrorCodeInvalidRequest, "update with force");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a.b"})"),
           helper::kErrorCodeInvalidRequest, "install missing force");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a.b","force":"yes"})"),
           helper::kErrorCodeInvalidRequest, "force not boolean");
  // 字符集：requestId/appId 禁止 `/`、`:`、空白与控制字符（§6.3）。
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t/1","operation":"install","appId":"a.b","force":false})"),
           helper::kErrorCodeInvalidRequest, "requestId with slash");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a b","force":false})"),
           helper::kErrorCodeInvalidRequest, "appId with space");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a:b","force":false})"),
           helper::kErrorCodeInvalidRequest, "appId with colon");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a/../b","force":false})"),
           helper::kErrorCodeInvalidRequest, "appId with path traversal");
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":"a.b","version":"1;rm -rf","force":false})"),
           helper::kErrorCodeInvalidRequest, "version with shell metachar");
  // 长度边界。
  const std::string longId(129, 'a');
  expectEq(parseFatalCode(
               R"({"v":1,"type":"cancel","requestId":")" + longId + R"("})"),
           helper::kErrorCodeInvalidRequest, "requestId over 128 bytes");
  const std::string longAppId(256, 'a');
  expectEq(parseFatalCode(
               R"({"v":1,"type":"start","requestId":"t","operation":"install","appId":")" +
                   longAppId + R"(","force":false})"),
           helper::kErrorCodeInvalidRequest, "appId over 255 bytes");
  expectEq(parseFatalCode(""), helper::kErrorCodeInvalidRequest,
           "empty line rejected");
}

void testCharsetValidators() {
  expectTrue(helper::isValidRequestId("a"), "requestId min length");
  expectTrue(helper::isValidRequestId(std::string(128, 'a')),
             "requestId max length");
  expectTrue(!helper::isValidRequestId(""), "requestId empty");
  expectTrue(!helper::isValidRequestId("太空"), "requestId non-ascii");
  expectTrue(helper::isValidAppId("org.deepin.demo-1_x"), "appId charset");
  expectTrue(!helper::isValidAppId("org/deepin"), "appId slash");
  expectTrue(helper::isValidVersion("1.2.3+deepin~beta1-2"),
             "version charset");
  expectTrue(!helper::isValidVersion("1 2"), "version space");
}

// ---- 事件编码 ----

void testEventEncoding() {
  expectTrue(helper::encodeReady() == R"({"type":"ready","v":1})" "\n",
             "ready encoding");
  expectEq(helper::encodeStarted("t1", 42),
           R"({"pid":42,"requestId":"t1","type":"started","v":1})" "\n",
           "started encoding");
  expectEq(helper::encodeOutput("t1", false, R"(a "b" \ c)"),
           R"({"line":"a \"b\" \\ c","requestId":"t1","stream":"stdout","type":"output","v":1})" "\n",
           "output escapes quotes and backslash");
  expectEq(helper::encodeOutput("t1", true, "x\ny"),
           R"({"line":"x\ny","requestId":"t1","stream":"stderr","type":"output","v":1})" "\n",
           "output escapes newline keeps framing");
  expectEq(helper::encodeCancelAccepted("t1"),
           R"({"requestId":"t1","type":"cancelAccepted","v":1})" "\n",
           "cancelAccepted encoding");
  expectEq(helper::encodeExited("t1", 1, true),
           R"({"cancelRequested":true,"exitCode":1,"requestId":"t1","type":"exited","v":1})" "\n",
           "exited encoding");
  expectEq(helper::encodeError(nullptr, "busy", "msg", false),
           R"({"code":"busy","fatal":false,"message":"msg","type":"error","v":1})" "\n",
           "session error encoding omits requestId");
  std::string id = "t1";
  expectEq(helper::encodeError(&id, "internal", "m", true),
           R"({"code":"internal","fatal":true,"message":"m","requestId":"t1","type":"error","v":1})" "\n",
           "task error encoding");
  // 超长 message 截断到 256 字节以内，且保持合法 JSON。
  const std::string longMessage(10000, 'x');
  const std::string encoded =
      helper::encodeError(nullptr, "internal", longMessage, true);
  expectTrue(encoded.size() < 600, "long message truncated");
}

// ---- 白名单 argv 与串行状态机 ----

void testArgvWhitelist() {
  helper::TaskSpec spec;
  spec.requestId = "t";
  spec.operation = helper::HelperOperation::kInstall;
  spec.appId = "org.deepin.demo";
  spec.force = false;
  expectArgv(helper::HelperTaskRunner::buildArgv(spec),
             {"/usr/bin/ll-cli", "install", "--json", "org.deepin.demo"},
             "install plain argv");

  spec.version = "1.2.3";
  expectArgv(helper::HelperTaskRunner::buildArgv(spec),
             {"/usr/bin/ll-cli", "install", "--json", "org.deepin.demo/1.2.3"},
             "install with version argv");

  spec.force = true;
  expectArgv(helper::HelperTaskRunner::buildArgv(spec),
             {"/usr/bin/ll-cli", "install", "--json", "org.deepin.demo/1.2.3",
              "--force"},
             "install force argv");

  spec.operation = helper::HelperOperation::kUpdate;
  spec.version = "9.9.9";
  spec.force = true;
  expectArgv(helper::HelperTaskRunner::buildArgv(spec),
             {"/usr/bin/ll-cli", "upgrade", "--json", "org.deepin.demo"},
             "update maps to upgrade and drops version/force");
}

void testSerialStateMachine() {
  helper::HelperTaskRunner runner;
  expectTrue(runner.isIdle(), "starts idle");

  helper::TaskSpec first;
  first.requestId = "t1";
  first.operation = helper::HelperOperation::kInstall;
  first.appId = "org.deepin.a";
  runner.begin(first);
  expectTrue(!runner.isIdle(), "busy after begin");
  expectEq(runner.currentRequestId(), "t1", "current id");

  expectTrue(runner.decideCancel("t2") ==
                 helper::CancelDecision::kNotRunning,
             "cancel other id rejected");
  expectTrue(runner.decideCancel("t1") == helper::CancelDecision::kAccepted,
             "cancel current id accepted");
  runner.markCancelRequested();
  expectTrue(runner.cancelRequested(), "cancel requested recorded");

  runner.finishCurrent();
  expectTrue(runner.isIdle(), "idle after finish");
  expectTrue(!runner.cancelRequested(), "cancel flag reset after finish");
  expectTrue(runner.decideCancel("t1") == helper::CancelDecision::kNotRunning,
             "cancel after finish rejected");
}

}  // namespace

int main() {
  testValidRequests();
  testInvalidRequests();
  testCharsetValidators();
  testEventEncoding();
  testArgvWhitelist();
  testSerialStateMachine();
  fprintf(stderr, "helper tests: %d checks, %d failures\n", gChecks, gFailures);
  return gFailures == 0 ? 0 : 1;
}
