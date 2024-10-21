#include "field.h"
#include "visionmodule.h"
#include "maintain.h"
#include "globaldata.h"
#include "parammanager.h"
#include "globalsettings.h"
#include "simulator.h"
#include "zss_debug.pb.h"
#include "rec_recorder.h"
#include <QColor>
#include <QtMath>
#include <QtDebug>
#include <iostream>
#include "geometry.h"
#include <QElapsedTimer>
#include <thread>
using namespace ZSS::Protocol;
namespace
{
    const static float MIN_LENGTH = 500; // area length : mm
    Qt::KeyboardModifiers mouse_modifiers;
    const static QColor CAR_COLOR[2] = {QColor(25, 30, 150), QColor(241, 201, 50)};
    const static QColor CAR_SHADOW[2] = {QColor(100, 120, 200, 50), QColor(255, 230, 150, 50)};
    const static QColor CAR_DIR[2] = {Qt::white, Qt::white};
    const static QColor FONT_COLOR[2] = {Qt::white, Qt::white};
    const static QColor DEBUG_COLOR[10] = {
        Qt::white,
        QColor(240, 53, 69),
        QColor(255, 100, 0),
        QColor(255, 240, 10),
        QColor(40, 207, 69),
        Qt::cyan,
        QColor(0, 120, 255),
        QColor(128, 0, 255),
        Qt::gray,
        Qt::black};
    const static QColor DEBUG_BRUSH_COLOR = QColor(255, 255, 255, 20);
    const static QColor COLOR_ORANGE(255, 0, 255);
    const static QColor COLOR_ORANGE_SHADOW(255, 0, 255, 60);
    const static QColor COLOR_TRANSORANGE(255, 170, 85, 100);
    const static QColor COLOR_DARKGREEN(30, 30, 30);
    const static QColor COLOR_RED(220, 53, 47);
    const static QColor COLOR_RED_SHADOW(220, 53, 47, 60);
    const static QColor COLOR_LIGHTWHITE(255, 255, 255, 20);
    const static QColor COLOR_BLUE(0, 137, 167);
    const static QColor COLOR_LIGHTBLUE(0, 137, 167, 50);
    const static QColor COLOR_GREEN(27, 129, 62);
    const static QColor COLOR_YELLOW(221, 210, 59);
    const static QColor COLOR_LIGHTYELLOW(221, 210, 59, 50);
    const static qreal zoomStep = 0.05;
    const static qreal zoomMin = 0.1;
    const int ballRatio = 3;
    int canvasHeight;
    int canvasWidth;
    int param_width;
    int param_height;
    int param_canvas_width;
    int param_canvas_height;
    int param_goalWidth;
    int param_goalDepth;
    int param_centerCircleRadius;
    int param_penaltyWidth;
    int param_penaltyLength;

    // /* ZJHU */
    // int player_buffer;
    // int player_ballrights_buffer;
    // int player_infraredcount_buffer;
    // int player_goalie;
    // int player_defender1;
    // int player_defender2;
    // /* ZJHU */

    auto zpm = ZSS::ZParamManager::instance();
    bool isSimulation;
    int ballDiameter;
    int shadowDiameter;
    int carDiameter;
    int carFaceWidth;
    int numberSize;
    int debugPointSize;
    qreal zoomRatio = 1;
    QPoint zoomStart = QPoint(0, 0);
    QRect area;
    // for field lines;
    QPainterPath painterPath;
    QPen pen = QPen(QColor(150, 150, 150), 1);
    double x(double _x)
    {
        return (_x * canvasWidth / param_canvas_width + canvasWidth / 2.0 - zoomStart.x()) / zoomRatio;
    }
    double y(double _y)
    {
        return (-_y * canvasHeight / param_canvas_height + canvasHeight / 2.0 - zoomStart.y()) / zoomRatio;
    }
    QPointF p(QPointF &_p)
    {
        return QPointF(x(_p.x()), y(_p.y()));
    }
    double w(double _w)
    {
        return _w * canvasWidth / param_canvas_width / zoomRatio;
    }
    double h(double _h)
    {
        return -_h * canvasHeight / param_canvas_height / zoomRatio;
    }
    double a(double _a)
    {
        return _a * 16;
    }
    double r(double _r)
    {
        return _r * 16;
    }
    double orx(double _x)
    {
        return (_x - canvasWidth / 2.0) * param_canvas_width / canvasWidth;
    }
    double ory(double _y)
    {
        return -(_y - canvasHeight / 2.0) * param_canvas_height / canvasHeight;
    }
    double orw(double _w)
    {
        return (_w)*param_canvas_width / canvasWidth;
    }
    double orh(double _h)
    {
        return -(_h)*param_canvas_height / canvasHeight;
    }
    double rx(double x)
    {
        return ::orx(zoomStart.x() + x * zoomRatio);
    }
    double ry(double y)
    {
        return ::ory(zoomStart.y() + y * zoomRatio);
    }
    QPointF rp(const QPointF &p)
    {
        return QPointF(rx(p.x()), ry(p.y()));
    }
    double distance2(double dx, double dy)
    {
        return dx * dx + dy * dy;
    }
    template <typename T>
    T limitRange(T value, T minValue, T maxValue)
    {
        return value > maxValue ? maxValue : (value < minValue) ? minValue
                                                                : value;
    }
    auto GS = GlobalSettings::instance();

    // draw Score
    std::thread *score_thread = nullptr;

    // multi-car selected
    bool selectRobots;
    int robotAmount;
    int robotID[PARAM::ROBOTNUM];
    int robotTeam;
    auto originRobot = GlobalData::instance()->processRobot[0];
    auto _G = GlobalData::instance();
}
namespace LeftEvent
{
    QPoint start;
}
namespace MiddleEvent
{
    QPoint start;
    QPoint zoomStart;
}
qreal Field::getpredict_x()
{
    return Maintain::instance()->getpredict_x();
}
qreal Field::getpredict_y()
{
    return Maintain::instance()->getpredict_y();
}
Field::Field(QQuickItem *parent)
    : QQuickPaintedItem(parent), pixmap(nullptr), cameraMode(true), _type(-1), socket_score(nullptr)
{
    setFillColor(COLOR_DARKGREEN);
    zpm->loadParam(canvasHeight, "canvas/height", 960);
    zpm->loadParam(canvasWidth, "canvas/width", 1280);
    connect(VisionModule::instance(), SIGNAL(needDraw()), this, SLOT(draw()));
    setImplicitWidth(canvasWidth);
    setImplicitHeight(canvasHeight);
    pixmap = new QPixmap(QSize(canvasWidth, canvasHeight));
    pixmapPainter.begin(pixmap);
    score_pixmap = new QPixmap(QSize(canvasWidth, canvasHeight));
    scorePainter.begin(score_pixmap);
    score_pixmap_buffer = new QPixmap(QSize(canvasWidth, canvasHeight));
    scorebufferPainter.begin(score_pixmap_buffer);
    pixmapPainter.setRenderHint(QPainter::Antialiasing, true);
    //    pixmapPainter.setRenderHint(QPainter::TextAntialiasing, true);
    //    pixmapPainter.setRenderHint(QPainter::SmoothPixmapTransform, true);
    init();
    zpm->loadParam(isSimulation, "Alert/IsSimulation", false);
    zpm->loadParam(ballDiameter, "size/ballDiameter", 100);
    zpm->loadParam(shadowDiameter, "size/shadowDiameter", 30);
    zpm->loadParam(carDiameter, "size/carDiameter", 180);
    zpm->loadParam(carFaceWidth, "size/carFaceWidth", 120);
    zpm->loadParam(numberSize, "size/numberSize", 200);
    zpm->loadParam(debugPointSize, "size/debugPointSize", 5);

    // /* ZJHU */
    // zpm->loadParam(player_buffer, "ZJHU/player_buffer", 130);
    // zpm->loadParam(player_ballrights_buffer, "ZJHU/player_ballrights_buffer", 120);
    // zpm->loadParam(player_infraredcount_buffer, "ZJHU/player_infraredcount_buffer", 120);
    // zpm->loadParam(player_goalie, "ZJHU/player_goalie", 0);
    // zpm->loadParam(player_defender1, "ZJHU/player_defender1", 1);
    // zpm->loadParam(player_defender2, "ZJHU/player_defender2", 2);
    // /* ZJHU */

    setAcceptedMouseButtons(Qt::LeftButton | Qt::RightButton | Qt::MiddleButton);
    // setAcceptHoverEvents(true);
    connect(GS, SIGNAL(needRepaint()), this, SLOT(repaint()));
    resetAfterMouseEvent();

    // draw Score
    score_thread = new std::thread([&] {receiveScore();});
    // record
    ZRecRecorder::instance()->init();
}

void Field::setType(int t){
    this->_type = t;
    // check if type in selected_points(type:map<int, vector<pair<int, int>>>)
    std::scoped_lock lock(_G->selected_points_mutex);
    if(_G->selected_points.find(t) == _G->selected_points.end()) {
        _G->selected_points[t] = std::vector<std::pair<int, int>>();
    }
}

void Field::paint(QPainter* painter) {
//    painter->drawPixmap(area, *pixmap, QRect(zoomStart, ::size * zoomRatio));
    painter->drawPixmap(area, *pixmap);
}
void Field::mousePressEvent(QMouseEvent *e)
{
    pressed = e->buttons();
    checkClosestRobot(rx(e->x()), ry(e->y()));
    start = end = rp(e->pos());
    mouse_modifiers = e->modifiers();
    switch (pressed)
    {
    case Qt::LeftButton:
        leftPressEvent(e);
        break;
    case Qt::RightButton:
        rightPressEvent(e);
        break;
    case Qt::MiddleButton:
        middlePressEvent(e);
        break;
    default:
        break;
    }
    repaint();
}
void Field::mouseMoveEvent(QMouseEvent *e)
{
    end = rp(e->pos());
    switch (pressed)
    {
    case Qt::LeftButton:
        leftMoveEvent(e);
        break;
    case Qt::RightButton:
        rightMoveEvent(e);
        break;
    case Qt::MiddleButton:
        middleMoveEvent(e);
        break;
    default:
        break;
    }
    repaint();
}
void Field::mouseReleaseEvent(QMouseEvent *e)
{
    switch (pressed)
    {
    case Qt::LeftButton:
        leftReleaseEvent(e);
        break;
    case Qt::RightButton:
        rightReleaseEvent(e);
        break;
    case Qt::MiddleButton:
        middleReleaseEvent(e);
        break;
    default:
        break;
    }
    resetAfterMouseEvent();
    repaint();
    // Simulator::instance()->setBall(rx(e->x())/1000.0,ry(e->y())/1000.0);
}
void Field::resetAfterMouseEvent()
{
    pressed = 0;
    pressedRobot = false;
    start = end = QPoint(-9999, -9999);
    mouse_modifiers = Qt::NoModifier;
}
void Field::checkClosestRobot(double x, double y)
{
    double limit = carDiameter * carDiameter / 4;
    auto &vision = GlobalData::instance()->processRobot[0];
    for (int color = PARAM::BLUE; color <= PARAM::YELLOW; color++)
    {
        for (int j = 0; j < vision.robotSize[color]; j++)
        {
            auto &robot = vision.robot[color][j];
            if (distance2(robot.pos.x() - x, robot.pos.y() - y) < limit)
            {
                if (!selectRobots)
                {
                    robotAmount = 1;
                    robotID[0] = robot.id;
                    robotTeam = color;
                }
                pressedRobot = true;
                return;
            }
        }
    }
    pressedRobot = false;
}
void Field::leftMoveEvent(QMouseEvent *e)
{
    switch (mouse_modifiers)
    {
    case Qt::NoModifier:
        if (pressedRobot)
        {
            for (int i = 0; i < robotAmount; i++)
            {
                auto dir = GlobalData::instance()->processRobot[0].robot[robotTeam][Maintain::instance()->robotIndex[robotTeam][robotID[i]]].angle;
                Simulator::instance()->setRobot((rx(e->x()) - rx(LeftEvent::start.x())) / 1000.0 + originRobot.robot[robotTeam][Maintain::instance()->robotIndex[robotTeam][robotID[i]]].pos.x() / 1000, ry(e->y()) / 1000 - ry(LeftEvent::start.y()) / 1000.0 + originRobot.robot[robotTeam][Maintain::instance()->robotIndex[robotTeam][robotID[i]]].pos.y() / 1000, robotID[i], robotTeam == PARAM::YELLOW, dir * 180 / M_PI);
            }
        }
        else
        {
            Simulator::instance()->setBall(rx(e->x()) / 1000.0, ry(e->y()) / 1000.0);
        }
        break;
    case Qt::ControlModifier:
        leftCtrlModifierPressEvent(e);
        break;
    case Qt::AltModifier:
        leftAltModifierPressEvent(e);
        break;
    }
}
void Field::leftPressEvent(QMouseEvent *e)
{
    LeftEvent::start.setX(e->x());
    LeftEvent::start.setY(e->y());
    originRobot = GlobalData::instance()->processRobot[0];
    leftMoveEvent(e);
}
void Field::leftReleaseEvent(QMouseEvent *e)
{
    switch (mouse_modifiers)
    {
    case Qt::NoModifier:
        leftMoveEvent(e);
        break;
    case Qt::ControlModifier:
        leftCtrlModifierReleaseEvent(e);
        break;
    case Qt::AltModifier:
        leftAltModifierReleaseEvent(e);
        break;
    }
}
void Field::leftCtrlModifierMoveEvent(QMouseEvent *e)
{
    auto x1 = ::rx(e->x());
    auto x2 = ::rx(LeftEvent::start.x());
    auto y1 = ::ry(e->y());
    auto y2 = ::ry(LeftEvent::start.y());
    auto minX = std::min(x1, x2);
    auto maxX = std::max(x1, x2);
    auto minY = std::min(y1, y2);
    auto maxY = std::max(y1, y2);
    if (maxX - minX < MIN_LENGTH * zoomRatio || maxY - minY < MIN_LENGTH * zoomRatio)
    {
        GlobalSettings::instance()->resetSelectCarArea();
        robotAmount = 0;
        std::fill_n(robotID, PARAM::ROBOTNUM, -1);
    }
    else
    {
        robotTeam = PARAM::BLUE;
        GlobalSettings::instance()->setSelectCarArea(minX, maxX, minY, maxY);
    }
}
void Field::leftCtrlModifierPressEvent(QMouseEvent *e)
{
    leftCtrlModifierMoveEvent(e);
}
void Field::leftCtrlModifierReleaseEvent(QMouseEvent *e)
{
    leftCtrlModifierMoveEvent(e);
    robotAmount = 0;
    auto &vision = GlobalData::instance()->processRobot[0];
    for (int j = 0; j < vision.robotSize[robotTeam]; j++)
    {
        auto &robot = vision.robot[robotTeam][j];
        if (robot.pos.x() < GS->selectCarMaxX && robot.pos.x() > GS->selectCarMinX && robot.pos.y() < GS->selectCarMaxY && robot.pos.y() > GS->selectCarMinY)
        {
            robotAmount++;
            robotID[robotAmount - 1] = robot.id;
        }
    }
    selectRobots = robotAmount > 0 ? true : false;
    GlobalSettings::instance()->resetSelectCarArea();
}
void Field::leftAltModifierMoveEvent(QMouseEvent *e)
{
    auto x1 = ::rx(e->x());
    auto x2 = ::rx(LeftEvent::start.x());
    auto y1 = ::ry(e->y());
    auto y2 = ::ry(LeftEvent::start.y());
    auto minX = std::min(x1, x2);
    auto maxX = std::max(x1, x2);
    auto minY = std::min(y1, y2);
    auto maxY = std::max(y1, y2);
    if (maxX - minX < MIN_LENGTH * zoomRatio || maxY - minY < MIN_LENGTH * zoomRatio)
    {
        GlobalSettings::instance()->resetSelectCarArea();
        robotAmount = 0;
        std::fill_n(robotID, PARAM::ROBOTNUM, -1);
    }
    else
    {
        robotTeam = PARAM::YELLOW;
        GlobalSettings::instance()->setSelectCarArea(minX, maxX, minY, maxY);
    }
}
void Field::leftAltModifierPressEvent(QMouseEvent *e)
{
    leftAltModifierMoveEvent(e);
}
void Field::leftAltModifierReleaseEvent(QMouseEvent *e)
{
    leftAltModifierMoveEvent(e);
    robotAmount = 0;
    auto &vision = GlobalData::instance()->processRobot[0];
    for (int j = 0; j < vision.robotSize[robotTeam]; j++)
    {
        auto &robot = vision.robot[robotTeam][j];
        if (robot.pos.x() < GS->selectCarMaxX && robot.pos.x() > GS->selectCarMinX && robot.pos.y() < GS->selectCarMaxY && robot.pos.y() > GS->selectCarMinY)
        {
            robotAmount++;
            robotID[robotAmount - 1] = robot.id;
        }
    }
    selectRobots = robotAmount > 0 ? true : false;
    GlobalSettings::instance()->resetSelectCarArea();
}
void Field::rightNoModifierMoveEvent(QMouseEvent *e) {
    QLineF line(start, end);
    if (pressedRobot)
    {
        displayData = -line.angle();
        if (displayData < -180)
            displayData += 360;
        for (int i = 0; i < robotAmount; i++)
        {
            auto &robot = GlobalData::instance()->processRobot[0].robot[robotTeam][Maintain::instance()->robotIndex[robotTeam][robotID[i]]];
            Simulator::instance()->setRobot(robot.pos.x() / 1000, robot.pos.y() / 1000, robotID[i], robotTeam == PARAM::YELLOW, displayData);
        }
    }
    else
    {
        displayData = ballRatio * line.length() / 1000.0;
    }
}
void Field::rightNoModifierPressEvent(QMouseEvent *e) {
}
void Field::rightNoModifierReleaseEvent(QMouseEvent *e) {
    QLineF line(start, end);
    if (!pressedRobot)
    {
        Simulator::instance()->setBall(start.x() / 1000.0, start.y() / 1000.0, ballRatio * line.dx() / 1000.0, ballRatio * line.dy() / 1000.0);
    }
}

void Field::rightMoveEvent(QMouseEvent *e){
    switch(mouse_modifiers) {
    case Qt::NoModifier:
        rightNoModifierMoveEvent(e);
        break;
    case Qt::ControlModifier:
        rightCtrlModifierMoveEvent(e);
        break;
    case Qt::AltModifier:
        rightAltModifierMoveEvent(e);
        break;
    default:
        break;
    }
}
void Field::rightPressEvent(QMouseEvent *e){
    switch(mouse_modifiers) {
    case Qt::NoModifier:
        rightNoModifierPressEvent(e);
        break;
    case Qt::ControlModifier:
        rightCtrlModifierPressEvent(e);
        break;
    case Qt::AltModifier:
        rightAltModifierPressEvent(e);
        break;
    default:
        break;
    }
}
void Field::rightReleaseEvent(QMouseEvent *e){
    switch(mouse_modifiers) {
    case Qt::NoModifier:
        rightNoModifierReleaseEvent(e);
        break;
    case Qt::ControlModifier:
        rightCtrlModifierReleaseEvent(e);
        break;
    case Qt::AltModifier:
        rightAltModifierReleaseEvent(e);
        break;
    default:
        break;
    }
}
void Field::rightCtrlModifierMoveEvent(QMouseEvent *e){
}
void Field::rightCtrlModifierPressEvent(QMouseEvent *e){
}
void Field::rightCtrlModifierReleaseEvent(QMouseEvent *e){
    std::scoped_lock lock(_G->selected_points_mutex);
    if(_G->selected_points.find(_type) == _G->selected_points.end()) {
        _G->selected_points[_type] = std::vector<std::pair<int, int>>();
    }
    auto pos = rp(e->pos());
    _G->selected_points[_type].push_back(std::pair<int, int>(pos.x(), pos.y()));
}
void Field::rightAltModifierMoveEvent(QMouseEvent *e){
}
void Field::rightAltModifierPressEvent(QMouseEvent *e){
}
void Field::rightAltModifierReleaseEvent(QMouseEvent *e){
    std::scoped_lock lock(_G->selected_points_mutex);
    if(_G->selected_points.find(_type) == _G->selected_points.end()) {
        _G->selected_points[_type] = std::vector<std::pair<int, int>>();
    }
    _G->selected_points[_type].clear();
}

void Field::middleMoveEvent(QMouseEvent *e) {
    switch(mouse_modifiers) {
    case Qt::NoModifier:
        middleNoModifierMoveEvent(e);
        break;
    case Qt::AltModifier:
        middleAltModifierMoveEvent(e);
        break;
    case Qt::ControlModifier:
        middleCtrlModifierMoveEvent(e);
        break;
    default:
        break;
    }
}
void Field::middlePressEvent(QMouseEvent *e)
{
    MiddleEvent::start.setX(e->x());
    MiddleEvent::start.setY(e->y());
    switch (mouse_modifiers)
    {
    case Qt::NoModifier:
        middleNoModifierPressEvent(e);
        break;
    case Qt::AltModifier:
        middleAltModifierPressEvent(e);
        break;
    case Qt::ControlModifier:
        middleCtrlModifierPressEvent(e);
        break;
    default:
        break;
    }
}
void Field::middleReleaseEvent(QMouseEvent *e)
{
    switch (mouse_modifiers)
    {
    case Qt::NoModifier:
        middleNoModifierReleaseEvent(e);
        break;
    case Qt::AltModifier:
        middleAltModifierReleaseEvent(e);
        break;
    case Qt::ControlModifier:
        middleCtrlModifierReleaseEvent(e);
        break;
    default:
        break;
    }
}
void Field::middleNoModifierMoveEvent(QMouseEvent *e)
{
    auto t = MiddleEvent::zoomStart + zoomRatio * (MiddleEvent::start - QPoint(e->x(), e->y()));
    zoomStart.setX(limitRange(t.x(), 0, int(area.width() * (1 - zoomRatio))));
    zoomStart.setY(limitRange(t.y(), 0, int(area.height() * (1 - zoomRatio))));
    initPainterPath();
}
void Field::middleNoModifierPressEvent(QMouseEvent *e)
{
    MiddleEvent::zoomStart = zoomStart;
}
void Field::middleNoModifierReleaseEvent(QMouseEvent *e) {}
void Field::middleAltModifierMoveEvent(QMouseEvent *e)
{
    middleAltModifierPressEvent(e);
}
void Field::middleAltModifierPressEvent(QMouseEvent *e)
{
    GlobalSettings::instance()->setBallPlacementPos(::rx(e->x()), ::ry(e->y()));
}
void Field::middleAltModifierReleaseEvent(QMouseEvent *e)
{
    middleAltModifierPressEvent(e);
}
void Field::middleCtrlModifierMoveEvent(QMouseEvent *e)
{
    auto x1 = ::rx(e->x());
    auto x2 = ::rx(MiddleEvent::start.x());
    auto y1 = ::ry(e->y());
    auto y2 = ::ry(MiddleEvent::start.y());
    auto minX = std::min(x1, x2);
    auto maxX = std::max(x1, x2);
    auto minY = std::min(y1, y2);
    auto maxY = std::max(y1, y2);
    if (maxX - minX < MIN_LENGTH * zoomRatio || maxY - minY < MIN_LENGTH * zoomRatio)
        GlobalSettings::instance()->resetArea();
    else
        GlobalSettings::instance()->setArea(minX, maxX, minY, maxY);
}
void Field::middleCtrlModifierPressEvent(QMouseEvent *e)
{
    middleCtrlModifierMoveEvent(e);
}
void Field::middleCtrlModifierReleaseEvent(QMouseEvent *e)
{
    middleCtrlModifierMoveEvent(e);
}
#if QT_CONFIG(wheelevent)
void Field::wheelEvent(QWheelEvent *e)
{
    qreal oldRatio = zoomRatio;
    zoomRatio += (e->delta() < 0 ? zoomStep : -zoomStep);
    zoomRatio = limitRange(zoomRatio, zoomMin, 1.0);
    zoomStart -= e->pos() * (zoomRatio - oldRatio);
    zoomStart.setX(limitRange(zoomStart.x(), 0, int(area.width() * (1 - zoomRatio))));
    zoomStart.setY(limitRange(zoomStart.y(), 0, int(area.height() * (1 - zoomRatio))));
    pixmapPainter.setRenderHint(QPainter::Antialiasing, zoomRatio > 0.5);
    initPainterPath();
    repaint();
}
#endif
void Field::setSize(int width, int height)
{
    canvasWidth = width;
    canvasHeight = height;
    zpm->changeParam("canvas/height", canvasHeight);
    zpm->changeParam("canvas/width", canvasWidth);
}
void Field::init()
{
    // /* ZJHU */
    // zpm->loadParam(player_buffer, "ZJHU/player_buffer", 130);
    // zpm->loadParam(player_ballrights_buffer, "ZJHU/player_ballrights_buffer", 120);
    // zpm->loadParam(player_infraredcount_buffer, "ZJHU/player_infraredcount_buffer", 120);
    // zpm->loadParam(player_goalie, "ZJHU/player_goalie", 0);
    // zpm->loadParam(player_defender1, "ZJHU/player_defender1", 1);
    // zpm->loadParam(player_defender2, "ZJHU/player_defender2", 2);
    // /* ZJHU */

    zpm->loadParam(param_width, "field/width", 9000);
    zpm->loadParam(param_height, "field/height", 6000);
    zpm->loadParam(param_canvas_width, "field/canvasWidth", 9900);
    zpm->loadParam(param_canvas_height, "field/canvasHeight", 7425);
    zpm->loadParam(param_goalWidth, "field/goalWidth", 1000);
    zpm->loadParam(param_goalDepth, "field/goalDepth", 200);
    zpm->loadParam(param_penaltyWidth, "field/penaltyWidth", 1000);
    zpm->loadParam(param_penaltyLength, "field/penaltyLength", 2000);
    zpm->loadParam(param_centerCircleRadius, "field/centerCircleRadius", 500);
    ::area = QRect(0, 0, this->property("width").toReal(), this->property("height").toReal());
    //    ::size = QSize(this->property("width").toReal()/2.0, this->property("height").toReal()/2.0);
    pressedRobot = false;
    initPainterPath();
    repaint();
}
void Field::repaint()
{ // change here!!!!!!!
    //    if(_draw)
    //        return;
    //    if(repaint_mutex.try_lock()){
    this->update(area);
    if (!_draw && _type != -1)
        return;
    switch (_type)
    {
    case 1:
        pixmap->fill(COLOR_DARKGREEN);
        paintInit();
        drawOriginVision(0);
        break;
    case 2:
        pixmap->fill(COLOR_DARKGREEN);
        pixmapPainter.setOpacity(0.4);
        score_buffer_mutex.lock();
        pixmapPainter.drawPixmap(0, 0, *score_pixmap_buffer);
        score_buffer_mutex.unlock();
        pixmapPainter.setOpacity(1);
        paintInit();
        drawMaintainVision(0);
        if (selectRobots) paintSelectedCar();
        paintSelectedPoints();
        drawDebugMessages(PARAM::BLUE); //BLUE
        break;
    case 3:
        pixmap->fill(COLOR_DARKGREEN);
        score_mutex.lock();
        score_mutex.unlock();
        paintInit();
        drawMaintainVision(0);
        if (selectRobots) paintSelectedCar();
        paintSelectedPoints();
        drawDebugMessages(PARAM::YELLOW); //YELLOW
        break;
    default:
        pixmap->fill(COLOR_DARKGREEN);
        paintInit();
    }
    drawBallLine();
    //        repaint_mutex.unlock();
    //    }
}
void Field::paintInit()
{
    drawCtrlC();
    pixmapPainter.strokePath(painterPath, pen);
    drawSelectedArea();
}
void Field::draw()
{
    repaint();
}
void Field::drawBallLine() {
    if(pressed == Qt::RightButton && mouse_modifiers == Qt::NoModifier) {
        pixmapPainter.setBrush(QBrush(FONT_COLOR[0]));
        pixmapPainter.setPen(QPen(FONT_COLOR[0], ::w(20), Qt::DashLine));
        pixmapPainter.drawLine(p(start), p(end));
        pixmapPainter.drawText(p(end), QString::fromStdString(std::to_string(displayData)));
    }
}
void Field::initPainterPath()
{
    pen.setWidth(::w(30));
    painterPath = QPainterPath();
    painterPath.addRect(::x(-param_width / 2.0), ::y(-param_height / 2.0), ::w(param_width), ::h(param_height));
    painterPath.addRect(::x(-param_width / 2.0), ::y(-param_goalWidth / 2.0), ::w(-param_goalDepth), ::h(param_goalWidth));
    painterPath.addRect(::x(param_width / 2.0), ::y(-param_goalWidth / 2.0), ::w(param_goalDepth), ::h(param_goalWidth));
    painterPath.moveTo(::x(-param_width / 2.0), ::y(0));
    painterPath.lineTo(::x(param_width / 2.0), ::y(0));
    painterPath.moveTo(::x(0), ::y(param_height / 2.0));
    painterPath.lineTo(::x(0), ::y(-param_height / 2.0));
    painterPath.addEllipse(::x(-param_centerCircleRadius), ::y(-param_centerCircleRadius), ::w(2 * param_centerCircleRadius), ::h(2 * param_centerCircleRadius));
    painterPath.addRect(::x(-param_width / 2.0), ::y(-param_penaltyLength / 2.0), ::w(param_penaltyWidth), ::h(param_penaltyLength));
    painterPath.addRect(::x(param_width / 2.0), ::y(-param_penaltyLength / 2.0), ::w(-param_penaltyWidth), ::h(param_penaltyLength));
    double penaltyPointWidth = 15;
    painterPath.addRect(::x(-param_width / 6.0 - penaltyPointWidth), ::y(0 - penaltyPointWidth), ::w(2 * penaltyPointWidth), ::h(2 * penaltyPointWidth));
    painterPath.addRect(::x(param_width / 6.0 - penaltyPointWidth), ::y(0 - penaltyPointWidth), ::w(2 * penaltyPointWidth), ::h(2 * penaltyPointWidth));
}
void Field::drawOriginVision(int index)
{
    for (int i = 0; i < PARAM::CAMERA; i++)
    {
        if (GlobalData::instance()->cameraControl[i] == true)
            drawVision(GlobalData::instance()->camera[i][index]);
    }
    for (int i = 0; i < PARAM::CAMERA; i++)
    {
        if (GlobalData::instance()->cameraControl[i] == true)
        {
            pixmapPainter.setBrush(Qt::NoBrush);
            pixmapPainter.setPen(COLOR_DARKGREEN);
            pixmapPainter.drawRect(QRect(QPoint(::x(GlobalData::instance()->cameraMatrix[i].leftedge.min), ::y(GlobalData::instance()->cameraMatrix[i].downedge.min)), QPoint(::x(GlobalData::instance()->cameraMatrix[i].rightedge.min), ::y(GlobalData::instance()->cameraMatrix[i].upedge.min))));
            pixmapPainter.setPen(COLOR_RED);
            pixmapPainter.drawRect(QRect(QPoint(::x(GlobalData::instance()->cameraMatrix[i].leftedge.max), ::y(GlobalData::instance()->cameraMatrix[i].downedge.max)), QPoint(::x(GlobalData::instance()->cameraMatrix[i].rightedge.max), ::y(GlobalData::instance()->cameraMatrix[i].upedge.max))));
            pixmapPainter.setFont(QFont("Ubuntu Mono", 13, QFont::Bold));
            pixmapPainter.drawText(::x(GlobalData::instance()->cameraMatrix[i].campos.x() - 100), ::y(GlobalData::instance()->cameraMatrix[i].campos.y()), "Camera" + QString::number(i));
        }
    }
}
void Field::drawMaintainVision(int index)
{
    for (int i = -99; i < 0; i++)
    {
        //        drawVision(GlobalData::instance()->maintain[index + i],true);
        auto &ball = GlobalData::instance()->maintain[index + i].ball[0];
        paintShadow(COLOR_TRANSORANGE, ball.pos.x(), ball.pos.y());
    }
    const OriginMessage &robot_vision = GlobalData::instance()->processRobot[index];
    auto last_touch = GlobalData::instance()->lastTouch % PARAM::ROBOTMAXID;
    auto last_touch_team = GlobalData::instance()->lastTouch < PARAM::ROBOTMAXID ? PARAM::BLUE : PARAM::YELLOW;
    if (last_touch < PARAM::ROBOTMAXID)
        for (int color = PARAM::BLUE; color <= PARAM::YELLOW; color++)
        {
            for (int j = 0; j < robot_vision.robotSize[color]; j++)
            {
                auto &robot = robot_vision.robot[color][j];
                paintCar(CAR_COLOR[color], robot.id, robot.pos.x(), robot.pos.y(), robot.angle, true, FONT_COLOR[color], false /*robot.id == last_touch && color == last_touch_team*/);
                //            paintCarShadow(robot.pos.x(), robot.pos.y(), robot.angle);
            }
        }

    auto &maintain = GlobalData::instance()->maintain[index];

    for (int color = PARAM::BLUE; color <= PARAM::YELLOW; color++)
    {
        for (int j = 0; j < maintain.robotSize[color]; j++)
        {
            auto &robot = maintain.robot[color][j];
            paintCarShadow(CAR_SHADOW[color], robot.pos.x(), robot.pos.y(), robot.angle);
        }
    }
    for (int j = 0; j < maintain.ballSize; j++)
    {
        auto &ball = maintain.ball[j];
        paintBall(ball.valid ? COLOR_ORANGE : COLOR_ORANGE_SHADOW, ball.pos.x(), ball.pos.y());
        //        paintFocus(ball.valid ? COLOR_RED : COLOR_RED_SHADOW, ball.pos.x(), ball.pos.y(), 500, ballFocusCount++);
    }
}
void Field::paintCar(const QColor &color, quint8 num, qreal x, qreal y, qreal radian, bool ifDrawNum, const QColor &textColor, bool needCircle)
{
    static qreal radius = carDiameter / 2.0;
    static qreal chordAngel = qRadiansToDegrees(qAcos(1.0 * carFaceWidth / carDiameter));
    pixmapPainter.setBrush(QBrush(color));
    pixmapPainter.setPen(QPen(COLOR_RED, ::w(30), Qt::DotLine));
    pixmapPainter.drawLine(QPointF(::x(x), ::y(y)), QPointF(::x(x), ::y(y)) + QPointF(::w(200) * qSin(radian + M_PI_2), ::w(200) * qCos(radian + M_PI_2)));
    pixmapPainter.setPen(Qt::NoPen);
    pixmapPainter.drawChord(QRectF(::x(x - radius), ::y(y - radius), ::w(2 * radius), ::h(2 * radius)), ::a(90.0 - chordAngel + 180 / M_PI * radian), ::r(180.0 + 2 * chordAngel));
    if (needCircle)
    {
        pixmapPainter.setBrush(Qt::NoBrush);
        pixmapPainter.setPen(QPen(COLOR_RED, ::w(30)));
        pixmapPainter.drawChord(QRectF(::x(x - radius), ::y(y - radius), ::w(2 * radius), ::h(2 * radius)), ::a(90.0 - chordAngel + 180 / M_PI * radian), ::r(180.0 + 2 * chordAngel));
    }
    if (ifDrawNum)
    {
        pixmapPainter.setBrush(Qt::NoBrush);
        pixmapPainter.setPen(QPen(textColor, ::w(30)));
        QFont font;
        int fontSize = ::h(-numberSize);
        font.setPixelSize(fontSize);
        pixmapPainter.setFont(font);
        pixmapPainter.drawText(::x(x - numberSize * 0.8), ::y(y + carDiameter * 0.35), QString::number(num, 16).toUpper());
    }
}
void Field::paintSelectedCar()
{
    static qreal radius = carDiameter / 2.0;
    static qreal chordAngel = qRadiansToDegrees(qAcos(1.0 * carFaceWidth / carDiameter));
    for (int i = 0; i < robotAmount; i++)
    {
        auto robot = GlobalData::instance()->processRobot[0].robot[robotTeam][Maintain::instance()->robotIndex[robotTeam][robotID[i]]];
        pixmapPainter.setBrush(Qt::NoBrush);
        pixmapPainter.setPen(QPen(COLOR_GREEN, ::w(50)));
        pixmapPainter.drawChord(QRectF(::x(robot.pos.x() - radius), ::y(robot.pos.y() - radius), ::w(2 * radius), ::h(2 * radius)), ::a(90.0 - chordAngel + 180 / M_PI * robot.angle), ::r(180.0 + 2 * chordAngel));
    }
}
void Field::paintSelectedPoints(){
    pixmapPainter.setBrush(QBrush(COLOR_GREEN));
    pixmapPainter.setPen(QPen(COLOR_GREEN, ::w(50)));
    float size = 20;
    std::scoped_lock lock(_G->selected_points_mutex);
    if(_G->selected_points.find(_type) == _G->selected_points.end()) {
        _G->selected_points[_type] = std::vector<std::pair<int, int>>();
    }
    auto points = _G->selected_points[_type];
    for (auto& p : points) {
        pixmapPainter.drawEllipse(QRectF(::x(p.first-size/2), ::y(p.second+size/2), ::w(size), ::h(-size)));
    }
}
void Field::paintCarShadow(const QColor& color,qreal x, qreal y, qreal radian) {
    static qreal radius = carDiameter / 2.0;
    static qreal chordAngel = qRadiansToDegrees(qAcos(1.0 * carFaceWidth / carDiameter));
    pixmapPainter.setBrush(QBrush(color));
    pixmapPainter.setPen(Qt::NoPen);
    //    pixmapPainter.drawLine(QPointF(::x(x), ::y(y)), QPointF(::x(x), ::y(y)) + QPointF(30 * qSin(radian + M_PI_2), 30 * qCos(radian + M_PI_2)));
    pixmapPainter.drawChord(QRectF(::x(x - radius), ::y(y - radius), ::w(2 * radius), ::h(2 * radius)), ::a(90.0 - chordAngel + 180 / M_PI * radian), ::r(180.0 + 2 * chordAngel));
}
void Field::paintBall(const QColor &color, qreal x, qreal y)
{
    pixmapPainter.setBrush(QBrush(color));
    pixmapPainter.setPen(Qt::NoPen);
    pixmapPainter.drawEllipse(QRectF(::x(x - ballDiameter / 2.0), ::y(y - ballDiameter / 2.0), ::w(ballDiameter), ::h(ballDiameter)));
}
void Field::paintpredict()
{
    pixmapPainter.setBrush(QBrush(Qt::black));
    pixmapPainter.setPen(Qt::NoPen);
    pixmapPainter.drawEllipse(::x(getpredict_x() - ballDiameter / 2.0), ::y(getpredict_y() - ballDiameter / 2.0), ::w(ballDiameter), ::h(ballDiameter));
}
void Field::paintShadow(const QColor &color, qreal x, qreal y)
{
    pixmapPainter.setBrush(QBrush(color));
    pixmapPainter.setPen(Qt::NoPen);
    pixmapPainter.drawEllipse(QRectF(::x(x - shadowDiameter / 2.0), ::y(y - shadowDiameter / 2.0), ::w(shadowDiameter), ::h(shadowDiameter)));
}
void Field::paintFocus(const QColor &color, qreal x, qreal y, qreal radian, qreal count)
{
    static int length = 40;
    pixmapPainter.setBrush(Qt::NoBrush);
    pixmapPainter.setPen(QPen(color, ::w(20)));
    pixmapPainter.drawEllipse(QRectF(::x(x - radian), ::y(y - radian), ::w(2 * radian), ::h(2 * radian)));
    pixmapPainter.setPen(QPen(color, ::w(30)));
    for (int i = 0; i < 4; i++)
    {
        pixmapPainter.drawLine(QPointF(::x(x + (radian + length) * qCos(count / 60.0 + i * M_PI / 2)), ::y(y + (radian + length) * qSin(count / 60.0 + i * M_PI / 2))), QPointF(::x(x + (radian - length) * qCos(count / 60.0 + i * M_PI / 2)), ::y(y + (radian - length) * qSin(count / 60.0 + i * M_PI / 2))));
    }
}
void Field::drawVision(const OriginMessage &vision, bool shadow)
{
    for (int color = PARAM::BLUE; color <= PARAM::YELLOW; color++)
    {
        for (int j = 0; j < vision.robotSize[color]; j++)
        {
            auto &robot = vision.robot[color][j];
            if (!shadow)
            {
                paintCar(CAR_COLOR[color], robot.id, robot.pos.x(), robot.pos.y(), robot.angle, true, FONT_COLOR[color]);
            }
            else
            {
                paintShadow(CAR_SHADOW[color], robot.pos.x(), robot.pos.y());
            }
        }
    }
    // paintpredict();
    for (int j = 0; j < vision.ballSize; j++)
    {
        auto &ball = vision.ball[j];
        if (!shadow)
        {
            paintBall(COLOR_ORANGE, ball.pos.x(), ball.pos.y());
        }
        else
        {
            paintShadow(COLOR_TRANSORANGE, ball.pos.x(), ball.pos.y());
        }
    }
}
void Field::drawCtrlC()
{
    pixmapPainter.setFont(QFont("Ubuntu Mono", 300, QFont::Bold));
    GlobalData::instance()->ctrlCMutex.lock();
    bool ctrlC = GlobalData::instance()->ctrlC;
    GlobalData::instance()->ctrlCMutex.unlock();
    if (ctrlC)
    {
        pixmapPainter.drawText(QPointF(0, 300), "CTRL_C");
    }
    pixmapPainter.setFont(QFont("Ubuntu Mono", 13, QFont::Bold));
}
void Field::drawSelectedArea()
{
    pixmapPainter.setBrush(QBrush(COLOR_LIGHTWHITE));
    pixmapPainter.setPen(Qt::NoPen);
    pixmapPainter.drawRect(QRectF(::x(GS->minimumX), ::y(GS->minimumY), ::w(GS->maximumX - GS->minimumX), ::h(GS->maximumY - GS->minimumY)));
    pixmapPainter.setPen(QPen(QBrush(robotTeam == PARAM::BLUE ? COLOR_LIGHTBLUE : COLOR_LIGHTYELLOW), 2));
    pixmapPainter.setBrush(QBrush(robotTeam == PARAM::BLUE ? COLOR_LIGHTBLUE : COLOR_LIGHTYELLOW));
    pixmapPainter.drawRect(QRectF(::x(GS->selectCarMinX), ::y(GS->selectCarMinY), ::w(GS->selectCarMaxX - GS->selectCarMinX), ::h(GS->selectCarMaxY - GS->selectCarMinY)));
}
void Field::drawDebugMessages(int team)
{
    static qreal chordAngel = qRadiansToDegrees(qAcos(1.0 * carFaceWidth / carDiameter));
    static Debug_Msgs msgs;
    GlobalData::instance()->debugMutex.lock();
    if (team == 0)
    {
        msgs.ParseFromArray(GlobalData::instance()->debugBlueMessages.data(), GlobalData::instance()->debugBlueMessages.size());
    }
    else
    {
        msgs.ParseFromArray(GlobalData::instance()->debugYellowMessages.data(), GlobalData::instance()->debugYellowMessages.size());
    }
    GlobalData::instance()->debugMutex.unlock();
    QFont font("Ubuntu Mono", ::w(200), QFont::Normal);
    pixmapPainter.setFont(font);
    pixmapPainter.setBrush(QBrush(DEBUG_BRUSH_COLOR));
    for (int i = 0; i < msgs.msgs_size(); i++)
    {
        auto &msg = msgs.msgs(i);
        pixmapPainter.setPen(QPen(DEBUG_COLOR[msg.color()], ::w(10)));
        double x1, x2, y1, y2;
        double minx, miny, maxx, maxy;
        switch (msg.type())
        {
        case Debug_Msg_Debug_Type_ARC:
            x1 = msg.arc().rect().point1().x();
            x2 = msg.arc().rect().point2().x();
            y1 = msg.arc().rect().point1().y();
            y2 = msg.arc().rect().point2().y();
            minx = std::min(x1, x2);
            miny = std::min(y1, y2);
            maxx = std::max(x1, x2);
            maxy = std::max(y1, y2);
            pixmapPainter.drawArc(QRectF(::x(double(minx)),
                                         ::y(double(miny)),
                                         ::w((maxx - minx)),
                                         ::h((maxy - miny))),
                                  msg.arc().start() * 16,
                                  msg.arc().span() * 16);

            break;
        case Debug_Msg_Debug_Type_LINE:
            pixmapPainter.drawLine(::x(msg.line().start().x()), ::y(msg.line().start().y()), ::x(msg.line().end().x()), ::y(msg.line().end().y()));
            break;
        case Debug_Msg_Debug_Type_POINTS:
        {
            QVector<QLine> lines;
            for (int i = 0; i < msg.points().point_size(); i++)
            {
                lines.push_back(QLine(::x((msg.points().point(i).x() + debugPointSize)), ::y((msg.points().point(i).y() + debugPointSize)), ::x((msg.points().point(i).x() - debugPointSize)), ::y((msg.points().point(i).y() - debugPointSize))));
                lines.push_back(QLine(::x((msg.points().point(i).x() - debugPointSize)), ::y((msg.points().point(i).y() + debugPointSize)), ::x((msg.points().point(i).x() + debugPointSize)), ::y((msg.points().point(i).y() - debugPointSize))));
            }
            pixmapPainter.drawLines(lines);
            break;
        }
        case Debug_Msg_Debug_Type_TEXT:
            font.setPointSizeF(::w(msg.text().size()));
            font.setWeight(msg.text().weight());
            pixmapPainter.setFont(font);
            pixmapPainter.drawText(QPointF(::x(msg.text().pos().x()), ::y(msg.text().pos().y())), QString::fromStdString(msg.text().text()));
            break;
        case Debug_Msg_Debug_Type_ROBOT:
            pixmapPainter.drawChord(QRectF(::x((msg.robot().pos().x()) - 1.2 * carDiameter / 2.0), ::y((msg.robot().pos().y()) + 1.2 * carDiameter / 2.0), ::w((1.2 * carDiameter)), ::h(-(1.2 * carDiameter))), ::a(90.0 - chordAngel - msg.robot().dir()), ::r(180.0 + 2 * chordAngel));
            break;
        // case Debug_Msg_Debug_Type_CURVE:
        // case Debug_Msg_Debug_Type_POLYGON:
        default:
            qDebug() << "debug message type not support!";
        }
    }
}
float Field::fieldXFromCoordinate(int x)
{
    return ::rx(x);
}
float Field::fieldYFromCoordinate(int y)
{
    return ::ry(y);
}

void Field::receiveScore() {
    socket_score = new QUdpSocket();
    socket_score->bind(QHostAddress(ZSS::LOCAL_ADDRESS), 20003);
    score_mutex.lock();
    score_pixmap->fill(COLOR_DARKGREEN);
    score_mutex.unlock();
    scorePainter.setPen(Qt::NoPen);
    while(true) {
        std::this_thread::sleep_for(std::chrono::microseconds(500));
        parseScores(socket_score);
    }
}

QColor cmap(const QString& cm, const float _v);
void Field::parseScores(QUdpSocket* const socket) {
    static QByteArray datagram;
    static Debug_Heatmap scores;
    while (socket->state() == QUdpSocket::BoundState && socket->hasPendingDatagrams()) {
        score_mutex.lock();
        score_pixmap->fill(COLOR_DARKGREEN);
        score_mutex.unlock();
        datagram.resize(socket->pendingDatagramSize());
        socket->readDatagram(datagram.data(), datagram.size());
        scores.ParseFromArray(datagram.data(), datagram.size());
        auto heat_size = scores.heat_size();
        auto cm = QString::fromStdString(scores.cmap());
        auto shape = scores.shape();
        score_mutex.lock();
        for(int i = 0; i < heat_size; i++) {
            auto score = scores.heat(i);
            auto size_x = score.x_size();
            auto size_y = score.y_size();
            auto size_v = score.value_size();
            auto size_s = score.size_size();
            if(size_x != size_y || (size_x != size_v && size_v != 1) || (size_x != size_s && size_s != 1)) {
                std::cerr << "DEBUG_SCORE : not correct size : " << size_x << " " << size_y << " " << size_v << std::endl;
                continue;
            }
            for(int k = 0; k < size_x; k++) {
                auto x = score.x(k);
                auto y = score.y(k);
                auto v = size_v == 1 ? score.value(0) : score.value(k);
                auto s = size_s == 1 ? score.size(0) : score.size(k);
                scorePainter.setBrush(cmap(cm,v));
                QRectF rect = QRectF(::x(x-s/2), ::y(y+s/2), ::w(s), ::h(-s));
                switch (shape) {
                case Debug_Heatmap_Shape_SQUARE:
                    scorePainter.drawRect(rect);
                    break;
                case Debug_Heatmap_Shape_CIRCLE:
                    scorePainter.drawEllipse(rect);
                    break;
                }
            }
        }
        score_mutex.unlock();
        score_buffer_mutex.lock();
        score_pixmap_buffer->fill(COLOR_DARKGREEN);
        scorebufferPainter.drawPixmap(0, 0, *score_pixmap);
        score_buffer_mutex.unlock();
    }
}

QColor cmap(const QString& cm, const float _v){
    static auto segValue = [](const float x,const std::map<float, float>& seg) {
        float x1 = seg.begin()->first;
        float y1 = seg.begin()->second;
        float x2 = x1;
        float y2 = y1;
        for(auto& [k, v] : seg) {
            if(k < x) {
                x1 = k;
                y1 = v;
            } else {
                x2 = k;
                y2 = v;
                break;
            }
        }
        if(std::fabs(x2 - x1) <= 1e-9) return y1;
        return y1 + (y2 - y1) / (x2 - x1) * (x - x1);
    };

    float v = std::clamp(_v,0.0f,1.0f);
    float r = 0.0f;
    float g = 0.0f;
    float b = 0.0f;
    if(cm == "jet"){
        r = segValue(v, {{0.0f, 0.0f}, {0.35f, 0.0f}, {0.65f, 1.0f}, {0.95f, 1.0f}, {1.0f, 0.5f}});
        g = segValue(v, {{0.0f, 0.0f}, {0.12f, 0.0f}, {0.37f, 1.0f}, {0.64f, 1.0f}, {0.90f, 0.0f}, {1.0f, 0.0f}});
        b = segValue(v, {{0.0f, 0.5f}, {0.1f, 1.0f}, {0.35f, 1.0f}, {0.65f, 0.0f}, {1.0f, 0.0f}});
    }else if(cm == "rainbow"){
        r = segValue(v, {{0.0f, 0.5f}, {0.25f, 0.0f}, {0.75f, 1.0f}, {1.0f, 1.0f}});
        g = -4*(v-0.5f)*(v-0.5) + 1.0f;
        b = -v*v + 1.0f;
    }else if(cm == "PiYG"){
        r = segValue(v, {{ 0.0f, 0.56f},{ 0.1f, 0.78f},{ 0.2f, 0.89f},{ 0.3f, 0.96f},{ 0.4f, 0.98f},{ 0.6f, 0.93f},{ 0.7f, 0.78f},{ 0.8f, 0.54f},{ 0.9f, 0.32f},{ 1.0f, 0.15f},});
        g = segValue(v, {{ 0.0f, 0.00f},{ 0.1f, 0.14f},{ 0.2f, 0.52f},{ 0.3f, 0.77f},{ 0.4f, 0.92f},{ 0.6f, 0.96f},{ 0.7f, 0.91f},{ 0.8f, 0.77f},{ 0.9f, 0.59f},{ 1.0f, 0.39f},});
        b = segValue(v, {{ 0.0f, 0.32f},{ 0.1f, 0.51f},{ 0.2f, 0.72f},{ 0.3f, 0.88f},{ 0.4f, 0.95f},{ 0.6f, 0.88f},{ 0.7f, 0.62f},{ 0.8f, 0.31f},{ 0.9f, 0.14f},{ 1.0f, 0.10f},});
    }else if(cm == "gray"){
        r = v;
        g = v;
        b = v;
    }else if(cm == "cool"){
        r = v;
        g = 1.0f - v;
        b = 1.0f;
    }else if(cm == "coolwarm"){
        r = segValue(v, {{ 0.0f, 0.23f},{ 0.1f, 0.36f},{ 0.2f, 0.51f},{ 0.3f, 0.67f},{ 0.4f, 0.80f},{ 0.6f, 0.92f},{ 0.7f, 0.97f},{ 0.8f, 0.94f},{ 0.9f, 0.85f},{ 1.0f, 0.71f},});
        g = segValue(v, {{ 0.0f, 0.30f},{ 0.1f, 0.48f},{ 0.2f, 0.65f},{ 0.3f, 0.78f},{ 0.4f, 0.85f},{ 0.6f, 0.83f},{ 0.7f, 0.72f},{ 0.8f, 0.55f},{ 0.9f, 0.35f},{ 1.0f, 0.02f},});
        b = segValue(v, {{ 0.0f, 0.75f},{ 0.1f, 0.90f},{ 0.2f, 0.99f},{ 0.3f, 0.99f},{ 0.4f, 0.93f},{ 0.6f, 0.78f},{ 0.7f, 0.61f},{ 0.8f, 0.44f},{ 0.9f, 0.28f},{ 1.0f, 0.15f},});
    }else if(cm == "seismic"){
        r = segValue(v, {{ 0.0f, 0.00f},{ 0.2f, 0.00f},{ 0.5f, 1.00f},{ 0.8f, 0.99f},{ 1.0f, 0.50f},});
        g = segValue(v, {{ 0.0f, 0.00f},{ 0.2f, 0.00f},{ 0.5f, 0.99f},{ 0.8f, 0.00f},{ 1.0f, 0.00f},});
        b = segValue(v, {{ 0.0f, 0.30f},{ 0.2f, 1.00f},{ 0.5f, 0.99f},{ 0.8f, 0.00f},{ 1.0f, 0.00f},});
    }else{
        r = 4 * v - 2;
        g = v < 0.5 ? 2 * v : 4 - 4 * v;
        b = -2 * v + 1;
    }
    return QColor(
        std::clamp(r,0.0f,1.0f)*255,
        std::clamp(g,0.0f,1.0f)*255,
        std::clamp(b,0.0f,1.0f)*255
    );
}