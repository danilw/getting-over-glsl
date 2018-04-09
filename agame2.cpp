#include <nanogui/opengl.h>
#include <nanogui/glutil.h>
#include <nanogui/screen.h>
#include <nanogui/window.h>
#include <nanogui/layout.h>
#include <nanogui/label.h>
#include <nanogui/checkbox.h>
#include <nanogui/button.h>
#include <nanogui/toolbutton.h>
#include <nanogui/popupbutton.h>
#include <nanogui/combobox.h>
#include <nanogui/progressbar.h>
#include <nanogui/entypo.h>
#include <nanogui/messagedialog.h>
#include <nanogui/textbox.h>
#include <nanogui/slider.h>
#include <nanogui/imagepanel.h>
#include <nanogui/imageview.h>
#include <nanogui/vscrollpanel.h>
#include <nanogui/colorwheel.h>
#include <nanogui/colorpicker.h>
#include <nanogui/graph.h>
#include <nanogui/tabwidget.h>
#include <iostream>
#include <string>
#include <emscripten.h>
#include <chrono>

// Includes for the GLTexture class.
#include <cstdint>
#include <memory>
#include <utility>

#if defined(__GNUC__)
#  pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif
#if defined(_WIN32)
#  pragma warning(push)
#  pragma warning(disable: 4457 4456 4005 4312)
#endif

//#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

#if defined(_WIN32)
#  pragma warning(pop)
#endif
#if defined(_WIN32)
#  if defined(APIENTRY)
#    undef APIENTRY
#  endif
#  include <windows.h>
#endif

using std::cout;
using std::cerr;
using std::endl;
using std::string;
using std::vector;
using std::pair;
using std::to_string;

class GLTexture {
public:
    using handleType = std::unique_ptr<uint8_t[], void(*)(void*)>;
    GLTexture() = default;
    GLTexture(const std::string& textureName)
        : mTextureName(textureName), mTextureId(0) {}

    GLTexture(const std::string& textureName, GLint textureId)
        : mTextureName(textureName), mTextureId(textureId) {}

    GLTexture(const GLTexture& other) = delete;
    GLTexture(GLTexture&& other) noexcept
        : mTextureName(std::move(other.mTextureName)),
        mTextureId(other.mTextureId) {
        other.mTextureId = 0;
    }
    GLTexture& operator=(const GLTexture& other) = delete;
    GLTexture& operator=(GLTexture&& other) noexcept {
        mTextureName = std::move(other.mTextureName);
        std::swap(mTextureId, other.mTextureId);
        return *this;
    }
    ~GLTexture() noexcept {
        if (mTextureId)
            glDeleteTextures(1, &mTextureId);
    }

    GLuint texture() const { return mTextureId; }
    const std::string& textureName() const { return mTextureName; }

    /**
    *  Load a file in memory and create an OpenGL texture.
    *  Returns a handle type (an std::unique_ptr) to the loaded pixels.
    */
    handleType load(const std::string& fileName, bool q,bool exf) {
        if (mTextureId) {
            glDeleteTextures(1, &mTextureId);
            mTextureId = 0;
        }
        int force_channels = 0;
        int w, h, n;
        handleType textureData(stbi_load(fileName.c_str(), &w, &h, &n, force_channels), stbi_image_free);
        if (!textureData){
            throw std::invalid_argument("Could not load texture data from file " + fileName);}
        glGenTextures(1, &mTextureId);
        glBindTexture(GL_TEXTURE_2D, mTextureId);
        GLint internalFormat;
        GLint format;
        switch (n) {
            case 1: internalFormat = GL_R8; format = GL_RED; break;
            case 2: internalFormat = GL_RG8; format = GL_RG; break;
            case 3: internalFormat = GL_RGB8; format = GL_RGB; break;
            case 4: internalFormat = GL_RGBA8; format = GL_RGBA; break;
            default: internalFormat = 0; format = 0; break;
        }
        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, w, h, 0, format, GL_UNSIGNED_BYTE, textureData.get());
        
        if(!exf){if(!q){
		glGenerateMipmap (GL_TEXTURE_2D);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
      }
        else{
			glGenerateMipmap (GL_TEXTURE_2D);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			
			}}else{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			}
        return textureData;
    }

private:
    std::string mTextureName;
    GLuint mTextureId;
};

// wasm does not work with callback "in same way like std C++", wasm lost "pointers" to anonymous and static defs in code ... maybe wasm bug 
// error in - if any of "widgets on window" call call_back once, this windows "can not use hide/show action" with wrong window pointer/ID at "glfw hide/show window" function in screen.cpp

// this is for avoiding it
nanogui::CheckBox *cb;
nanogui::Button *b;
nanogui::Button *b1;
nanogui::Button *b2;
nanogui::ColorPicker *cp1;
nanogui::FloatBox<float> *ftextBox;
nanogui::Window *window1;
bool paused=false;
bool resetx=true;
float pto=0;
float ptime=0;
bool antxtstate=true;
int indexfx[8]={0};
		
class ExampleApplication : public nanogui::Screen {
public:
    ExampleApplication() : nanogui::Screen(Eigen::Vector2i(1366, 768), "NanoGUI Test", /*resizable*/true, /*fullscreen*/false, /*colorBits*/8,
                                /*alphaBits*/8, /*depthBits*/24, /*stencilBits*/8,
                                /*nSamples*/0, /*glMajor*/3, /*glMinor*/0) {
        using namespace nanogui;
        window1 = new Window(this, "Menu");
        settextures();
        setBackground(Vector4f(0,0,0,1));
        b = new Button(this, "Menu");
        b->setBackgroundColor(Color(235, 0, 0, 255));
        b->setTextColor(Color(235, 235, 235, 255));
        b->setCallback([&] {
			window1->setVisible(!window1->visible());
			if(window1->visible())window1->setPosition(Vector2i(425, 300));
        });
        
        b1 = this->add<Button>("Pause");
        b1->setBackgroundColor(Color(0, 0, 205, 255));
        b1->setTextColor(Color(235, 235, 235, 255));
        b1->setPosition(Vector2i(0, 35));
        b1->setCallback([&] {
			paused=!paused;
			if(paused)pto=glfwGetTime();
			else{
				ptime=ptime+glfwGetTime()-pto;
				pto=0;
				}
        });
        
        b2 = this->add<Button>("Reset");
        b2->setTextColor(Color(235, 235, 235, 255));
        b2->setBackgroundColor(Color(205, 100, 0, 255));
        b2->setPosition(Vector2i(65, 0));
        b2->setCallback([&] {
			resetx=true;
        });
        
        
        
        window1->setPosition(Vector2i(425, 300));
        GridLayout *layout =
            new GridLayout(Orientation::Horizontal, 2,
                           Alignment::Middle, 15, 5);
        layout->setColAlignment(
            { Alignment::Maximum, Alignment::Fill });
        layout->setSpacing(0, 10);
        window1->setLayout(layout);
        
        new Label(window1, "Hide Menu buttons :", "sans-bold");

        cb = new CheckBox(window1, "");
        cb->setFontSize(16);
        cb->setChecked(false);
        cb->setCallback([&](bool state) {
			if(!state){b->setVisible(true);b1->setVisible(true);b2->setVisible(true);}
			else{b->setVisible(false);b1->setVisible(false);b2->setVisible(false);
				}
        });
        new Label(window1, "Desable anim/textures :", "sans-bold");
        CheckBox *cb2 = new CheckBox(window1, "");
        cb2->setFontSize(16);
        cb2->setChecked(false);
        cb2->setCallback([&](bool state) {
			antxtstate=!state;
        });
        
        new Label(window1, "Background color :", "sans-bold");
            ftextBox = new FloatBox<float>(window1);
            ftextBox->setEditable(true);
            ftextBox->setFixedSize(Vector2i(100, 20));
            ftextBox->setValue(2.6);
            ftextBox->setUnits("");
            ftextBox->setDefaultValue("0.0");
            ftextBox->setFontSize(16);
            ftextBox->setMinValue(0.0);
            ftextBox->setMaxValue(6.1);
            ftextBox->setSpinnable(true);
            ftextBox->setValueIncrement(0.1);
            ftextBox->setFormat("[-]?[0-9]*\\.?[0-9]+");
        
        new Label(window1, "Control :", "sans-bold");
        new Label(window1, "Mouse Left Click :)", "sans-bold");

        performLayout();
        window1->setVisible(false);
        
        fb1.inittexture(Vector2i(1280, 720));
        fb2.inittexture(Vector2i(1280, 720));
        fb3.inittexture(Vector2i(1, 1));
        fb4.inittexture(Vector2i(1280, 720));
        fb5.inittexture(Vector2i(1, 1));
        fb6.inittexture(Vector2i(1280, 720));
        fb7.inittexture(Vector2i(1280/1, 720/1));
        fb8.inittexture(Vector2i(1, 1));
        fb9.inittexture(Vector2i(1, 1));
        fb10.inittexture(Vector2i(1280, 720));
        fb11.inittexture(Vector2i(1280/1.5, 720/1.5));
        fb12.inittexture(Vector2i(1280/1.5, 720/1.5));
        fb13.inittexture(Vector2i(1280/1.5, 720/1.5));
        
        mShader2.initFromFiles("ba","shaders/mainv.glsl","shaders/ba.glsl");
        mShader.initFromFiles("bm","shaders/mainv.glsl","shaders/bm.glsl");
        mShader3.initFromFiles("bpha","shaders/mainv.glsl","shaders/bpha.glsl");
        mShader4.initFromFiles("bphb","shaders/mainv.glsl","shaders/bphb.glsl");
        mShader5.initFromFiles("bphm","shaders/mainv.glsl","shaders/bphm.glsl");
        mShader6.initFromFiles("cb1","shaders/mainv.glsl","shaders/cb.glsl");
        mShader7.initFromFiles("bb","shaders/mainv.glsl","shaders/bb.glsl");
        mShader8.initFromFiles("bc","shaders/mainv.glsl","shaders/bc.glsl");
        mShader9.initFromFiles("bd","shaders/mainv.glsl","shaders/bd.glsl");
        mShader10.initFromFiles("bdc","shaders/mainv.glsl","shaders/bdc.glsl");
        mShader11.initFromFiles("be","shaders/mainv.glsl","shaders/be.glsl");
        mShader12.initFromFiles("bra","shaders/mainv.glsl","shaders/bra.glsl");
        mShader13.initFromFiles("brb","shaders/mainv.glsl","shaders/brb.glsl");
        mShader14.initFromFiles("brc","shaders/mainv.glsl","shaders/brc.glsl");
        

        MatrixXu indices(3, 2); /* Draw 2 triangles */
        indices.col(0) << 0, 1, 2;
        indices.col(1) << 2, 3, 0;

        MatrixXf positions(3, 4);
        positions.col(0) << -1, -1, 0;
        positions.col(1) <<  1, -1, 0;
        positions.col(2) <<  1,  1, 0;
        positions.col(3) << -1,  1, 0;
        Vector2f screenSize = size().cast<float>();
        
        fb1.bind();
        mShader2.bind();
        mShader2.uploadIndices(indices);
        mShader2.uploadAttrib("position", positions);
        mShader2.setUniform("u_resolution", screenSize);

        fb1.release();
        
        fb2.bind();
        mShader3.bind();
        mShader3.uploadIndices(indices);
        mShader3.uploadAttrib("position", positions);
        mShader3.setUniform("u_resolution", screenSize);

        fb2.release();
        
        fb3.bind();
        mShader4.bind();
        mShader4.uploadIndices(indices);
        mShader4.uploadAttrib("position", positions);
        mShader4.setUniform("u_resolution", screenSize);

        fb3.release();
        
        fb4.bind();
        mShader5.bind();
        mShader5.uploadIndices(indices);
        mShader5.uploadAttrib("position", positions);
        mShader5.setUniform("u_resolution", screenSize);

        fb4.release();
        
        fb5.bind();
        mShader6.bind();
        mShader6.uploadIndices(indices);
        mShader6.uploadAttrib("position", positions);

        fb5.release();
        
        fb6.bind();
        mShader7.bind();
        mShader7.uploadIndices(indices);
        mShader7.uploadAttrib("position", positions);
        mShader7.setUniform("u_resolution", screenSize);

        fb6.release();
        
        fb7.bind();
        mShader8.bind();
        mShader8.uploadIndices(indices);
        mShader8.uploadAttrib("position", positions);
        mShader8.setUniform("u_resolution", screenSize);

        fb7.release();
        
        fb8.bind();
        mShader9.bind();
        mShader9.uploadIndices(indices);
        mShader9.uploadAttrib("position", positions);
        mShader9.setUniform("u_resolution", screenSize);

        fb8.release();
        
        fb9.bind();
        mShader10.bind();
        mShader10.uploadIndices(indices);
        mShader10.uploadAttrib("position", positions);

        fb9.release();
        
        fb10.bind();
        mShader11.bind();
        mShader11.uploadIndices(indices);
        mShader11.uploadAttrib("position", positions);
        mShader11.setUniform("u_resolution", screenSize);

        fb10.release();
        
        fb11.bind();
        mShader12.bind();
        mShader12.uploadIndices(indices);
        mShader12.uploadAttrib("position", positions);
        mShader12.setUniform("u_resolution", screenSize);

        fb11.release();
        
        fb12.bind();
        mShader13.bind();
        mShader13.uploadIndices(indices);
        mShader13.uploadAttrib("position", positions);
        mShader13.setUniform("u_resolution", screenSize);

        fb12.release();
        
        fb13.bind();
        mShader14.bind();
        mShader14.uploadIndices(indices);
        mShader14.uploadAttrib("position", positions);
        mShader14.setUniform("u_resolution", screenSize);

        fb13.release();
        
        


        mShader.bind();
        mShader.uploadIndices(indices);
        mShader.uploadAttrib("position", positions);
        mShader.setUniform("u_resolution", screenSize);
    }

    ~ExampleApplication() {
        mShader.free();
    }

    virtual bool keyboardEvent(int key, int scancode, int action, int modifiers) {
        if (Screen::keyboardEvent(key, scancode, action, modifiers))
            return true;
        if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
			//std::cout<<"Exit(ESC) called"<<std::endl;
            //setVisible(false);
            return true;
        }
        if (key == GLFW_KEY_P && action == GLFW_PRESS) {
			paused=!paused;
            return true;
        }
        
        return false;
    }
    
    Eigen::Vector2f umouse;
    
    virtual bool mouseMotionEvent(const Eigen::Vector2i &p, const Eigen::Vector2i &rel, int button, int modifiers ) {
	if (Screen::mouseMotionEvent(p, rel, button, modifiers)){return true;}
    //if ((button & (1 << GLFW_MOUSE_BUTTON_1)) != 0) {
		umouse=Eigen::Vector2f(p[0],p[1]);
		if(cb->checked()){if(p[0]<130&&p[1]<80){b->setVisible(true);b1->setVisible(true);b2->setVisible(true);}else{b->setVisible(false);b1->setVisible(false);b2->setVisible(false);}}
        //return true;
    //}
    return false;
}
    float ffm=false;
	virtual bool mouseButtonEvent(const Eigen::Vector2i &p, int button, bool down, int modifiers) {
	if (Screen::mouseButtonEvent(p, button, down, modifiers))
            return true;
    ffm=button == GLFW_MOUSE_BUTTON_1 && down;
    return false;
}

    virtual void draw(NVGcontext *ctx) {

        /* Draw the user interface */
        Screen::draw(ctx);
    }

double frameRateSmoothing = 1.0;
double numFrames = 0;
double fps = 0;

Eigen::Vector2f osize=Eigen::Vector2f(1280,720);
bool pausedonce=false;
bool trot=false;
bool rot=false;
    virtual void drawContents() {
        using namespace nanogui;
        
        std::chrono::duration<double> delta = std::chrono::duration_cast<std::chrono::duration<double>> (std::chrono::high_resolution_clock::now() - lastFpsTime);
        numFrames++;
        /*if (delta.count() > frameRateSmoothing) {
        fps = (int) (numFrames / delta.count());
        fpscapt->setValue(std::to_string((int) (fps)));
        numFrames = 0;*/
        lastFpsTime = std::chrono::high_resolution_clock::now();
        //}

        
        
        if(ffm&&!trot){
			trot=true;
			}
		if(trot&&!ffm){trot=false;rot=true;}
		if(resetx)ptime=glfwGetTime();
		
        updateallUnioforms();
        Vector2i tsxz=size();
        if((int)(tsxz[1]*(float)16/9)!=tsxz[0])tsxz[0]=(int)(tsxz[1]*(float)16/9);
        Vector2f screenSize = tsxz.cast<float>();
        pausedonce=(!(((osize - screenSize).norm() == 0)));
        osize=screenSize;
        glDisable(GL_BLEND);//framebuffer
        
        fb1.bind();
        mShader2.bind();
        mShader2.setUniform("u_resolution", screenSize);
        mShader2.setUniform("u_color", ftextBox->value());
        mShader2.drawIndexed(GL_TRIANGLES, 0, 2);
        fb1.release();
        
        fb2.bind();
        mShader3.bind();
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[0]].first.texture());
        mShader3.setUniform("u_texture1", 0);
        glActiveTexture(GL_TEXTURE0+1);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[1]].first.texture());
        mShader3.setUniform("u_texture2", 1);
        mShader3.setUniform("u_resolution", screenSize);
        mShader3.drawIndexed(GL_TRIANGLES, 0, 2);
        fb2.release();
        
        fb3.bind();
        mShader4.bind();
        fb2.bindtexture(tsxz,0);
        mShader4.setUniform("u_texture1", 0);
        fb5.bindtexture(Vector2i(1, 1),1,false);
        mShader4.setUniform("u_texture2", 1);
        mShader4.setUniform("ffm", (int)ffm);
        mShader4.setUniform("paused", (int)(paused||pausedonce));
        mShader4.setUniform("reset", (int)resetx);
        mShader4.setUniform("rot", (int)rot);
        mShader4.setUniform("u_resolution", screenSize);
        //mShader4.setUniform("u_time", (float) glfwGetTime());
        //mShader4.setUniform("u_mouse", umouse);
        mShader4.setUniform("iTimeDelta", (float)delta.count()>1.f/60?1.f/60:(float)delta.count());
        mShader4.drawIndexed(GL_TRIANGLES, 0, 2);
        fb3.release();
        
        fb5.bind();
        mShader6.bind();
        fb3.bindtexture(Vector2i(1, 1),0,false);
        mShader6.setUniform("u_texture1", 0);
        mShader6.drawIndexed(GL_TRIANGLES, 0, 2);
        fb5.release();
        
        fb6.bind();
        mShader7.bind();
        mShader7.setUniform("u_time", (float) glfwGetTime());
        fb3.bindtexture(Vector2i(1, 1),0,false);
        mShader7.setUniform("u_texture1", 0);
        mShader7.setUniform("u_resolution", screenSize);
        mShader7.drawIndexed(GL_TRIANGLES, 0, 2);
        fb6.release();
        
        fb4.bind();
        mShader5.bind();
        fb2.bindtexture(tsxz,0);
        mShader5.setUniform("u_texture1", 0);
        fb3.bindtexture(Vector2i(1, 1),1,false);
        mShader5.setUniform("u_texture2", 1);
        mShader5.setUniform("u_resolution", screenSize);
        mShader5.setUniform("antxtstate", (int)antxtstate);
        //mShader5.setUniform("u_time", (float) glfwGetTime());
        mShader5.drawIndexed(GL_TRIANGLES, 0, 2);
        fb4.release();
        
        fb7.bind();
        mShader8.bind();
        mShader8.setUniform("u_time", (float) glfwGetTime());
        fb8.bindtexture(Vector2i(1, 1),0,false);
        mShader8.setUniform("u_texture1", 0);
        fb3.bindtexture(Vector2i(1, 1),1,false);
        mShader8.setUniform("u_texture2", 1);
        mShader8.setUniform("u_resolution", Vector2f(screenSize[0]/1,screenSize[1]/1));
        mShader8.drawIndexed(GL_TRIANGLES, 0, 2);
        fb7.release();
        
        fb8.bind();
        mShader9.bind();
        mShader9.setUniform("u_time", (float) glfwGetTime()-ptime);
        fb3.bindtexture(Vector2i(1, 1),0,false);
        mShader9.setUniform("u_texture1", 0);
        fb9.bindtexture(Vector2i(1, 1),1,false);
        mShader9.setUniform("u_texture2", 1);
        mShader9.setUniform("u_resolution", screenSize);
        mShader9.drawIndexed(GL_TRIANGLES, 0, 2);
        fb8.release();
        
        fb9.bind();
        mShader10.bind();
        fb8.bindtexture(Vector2i(1, 1),0,false);
        mShader10.setUniform("u_texture1", 0);
        mShader10.drawIndexed(GL_TRIANGLES, 0, 2);
        fb9.release();
        
        
        fb10.bind();
        mShader11.bind();
        mShader11.setUniform("u_resolution", screenSize);
        mShader11.drawIndexed(GL_TRIANGLES, 0, 2);
        fb10.release();
        
        fb11.bind();
        mShader12.bind();
        glActiveTexture(GL_TEXTURE0+0);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[4]].first.texture());
        mShader12.setUniform("u_texture1", 0);
        glActiveTexture(GL_TEXTURE0+1);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[7]].first.texture());
        mShader12.setUniform("u_texture2", 1);
        mShader12.setUniform("u_time", (float) glfwGetTime());
        mShader12.setUniform("u_resolution", Vector2f(screenSize[0]/1.5,screenSize[1]/1.5));
        if(antxtstate)mShader12.drawIndexed(GL_TRIANGLES, 0, 2);
        fb11.release();
        
        fb12.bind();
        mShader13.bind();
        fb11.bindtexture(Vector2i(tsxz[0]/2,tsxz[1]/2),0);
        mShader13.setUniform("u_texture1", 0);
        fb13.bindtexture(Vector2i(tsxz[0]/2,tsxz[1]/2),1);
        mShader13.setUniform("u_texture2", 1);
        mShader13.setUniform("u_resolution", Vector2f(screenSize[0]/1.5,screenSize[1]/1.5));
        if(antxtstate)mShader13.drawIndexed(GL_TRIANGLES, 0, 2);
        fb12.release();
        
        fb13.bind();
        mShader14.bind();
        fb12.bindtexture(Vector2i(tsxz[0]/1.5,tsxz[1]/1.5),0);
        mShader14.setUniform("u_texture1", 0);
        mShader14.setUniform("u_resolution", Vector2f(screenSize[0]/1.5,screenSize[1]/1.5));
        if(antxtstate)mShader14.drawIndexed(GL_TRIANGLES, 0, 2);
        fb13.release();
        
        
        mShader.bind();
        fb1.bindtexture(tsxz,0);
        mShader.setUniform("u_texture1", 0);
        fb4.bindtexture(tsxz,1);
        mShader.setUniform("u_texture2", 1);
        fb6.bindtexture(tsxz,2);
        mShader.setUniform("u_texture3", 2);
        fb3.bindtexture(Vector2i(1, 1),3,false);
        mShader.setUniform("u_texture4", 3);
        fb7.bindtexture(Vector2i(tsxz[0]/1,tsxz[1]/1),4);
        mShader.setUniform("u_texture5", 4);
        fb10.bindtexture(tsxz,5);
        mShader.setUniform("u_texture6", 5);
        glActiveTexture(GL_TEXTURE0+6);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[0]].first.texture());
        mShader.setUniform("u_texture7", 6);
        glActiveTexture(GL_TEXTURE0+7);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[2]].first.texture());
        mShader.setUniform("u_texture8", 7);
        glActiveTexture(GL_TEXTURE0+8);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[3]].first.texture());
        mShader.setUniform("u_texture9", 8);
        glActiveTexture(GL_TEXTURE0+9);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[5]].first.texture());
        mShader.setUniform("u_texture10", 9);
        glActiveTexture(GL_TEXTURE0+10);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[6]].first.texture());
        mShader.setUniform("u_texture11", 10);
        glActiveTexture(GL_TEXTURE0+11);
        glBindTexture(GL_TEXTURE_2D, texturesData[indexfx[1]].first.texture());
        mShader.setUniform("u_texture12", 11);
        fb12.bindtexture(Vector2i(tsxz[0]/1.5,tsxz[1]/1.5),12);
        mShader.setUniform("u_texture13", 12);
        mShader.setUniform("u_resolution", screenSize);
        mShader.setUniform("ffm", (int)ffm);
        //mShader.setUniform("u_mouse", umouse);
        mShader.setUniform("antxtstate", (int)antxtstate);
        mShader.setUniform("u_time", (float) glfwGetTime());
        mShader.drawIndexed(GL_TRIANGLES, 0, 2);
        fb1.blittexture();
        fb2.blittexture();
        fb3.blittexture();
        fb4.blittexture();
        fb5.blittexture();
        fb6.blittexture();
        fb7.blittexture();
        fb8.blittexture();
        fb9.blittexture();
        fb10.blittexture();
        fb11.blittexture();
        fb12.blittexture();
        fb13.blittexture();
        resetx=false;
        if(glfwGetTime()-ptime>900)resetx=true;
        //pausedonce=false;
        rot=false;
        
    }
private:
    nanogui::ProgressBar *mProgress;
    nanogui::GLShader mShader;
    nanogui::GLShader mShader2;
    nanogui::GLShader mShader3;
    nanogui::GLShader mShader4;
    nanogui::GLShader mShader5;
    nanogui::GLShader mShader6;
    nanogui::GLShader mShader7;
    nanogui::GLShader mShader8;
    nanogui::GLShader mShader9;
    nanogui::GLShader mShader10;
    nanogui::GLShader mShader11;
    nanogui::GLShader mShader12;
    nanogui::GLShader mShader13;
    nanogui::GLShader mShader14;
    nanogui::GLFramebuffer fb1;
    nanogui::GLFramebuffer fb2;
    nanogui::GLFramebuffer fb3;
    nanogui::GLFramebuffer fb4;
    nanogui::GLFramebuffer fb5;
    nanogui::GLFramebuffer fb6;
    nanogui::GLFramebuffer fb7;
    nanogui::GLFramebuffer fb8;
    nanogui::GLFramebuffer fb9;
    nanogui::GLFramebuffer fb10;
    nanogui::GLFramebuffer fb11;
    nanogui::GLFramebuffer fb12;
    nanogui::GLFramebuffer fb13;
    std::chrono::high_resolution_clock::time_point lastFpsTime;
    
    void settextures();
    void updateallUnioforms();
    

    using imagesDataType = vector<pair<GLTexture, GLTexture::handleType>>;
    imagesDataType mImagesData;
    imagesDataType texturesData;
    int mCurrentImage;
};


























void ExampleApplication::settextures(){
	using namespace nanogui;
	vector<pair<int, string>> textres = loadImageDirectory(mNVGContext, "textures");
    string resourcesFolderPath("./");
    int i=0;
	for (auto& texturex : textres) {
            GLTexture texture(texturex.second);
            if(texturex.second==("textures/tx1")) //its fixes for "random non sorted file names in readdir(loadImageDirectory use it)"
            indexfx[0]=i;
            if(texturex.second==("textures/tx2"))
            indexfx[1]=i;
            if(texturex.second==("textures/tx3"))
            indexfx[2]=i;
            if(texturex.second==("textures/tx4"))
            indexfx[3]=i;
            if(texturex.second==("textures/tx5"))
            indexfx[4]=i;
            if(texturex.second==("textures/tx6"))
            indexfx[5]=i;
            if(texturex.second==("textures/tx7"))
            indexfx[6]=i;
            if(texturex.second==("textures/iqn"))
            indexfx[7]=i;
            bool fmt=texturex.second==("textures/tx6")||texturex.second==("textures/tx7");
            auto data = texture.load(resourcesFolderPath + texturex.second + ".png",fmt,false);
            texturesData.emplace_back(std::move(texture), std::move(data));
            i++;
    }
	}
	
void ExampleApplication::updateallUnioforms(){


	}






















void mainloop(){

	nanogui::mainloop();
}

int main(int /* argc */, char ** /* argv */) {
    try {
        nanogui::init();
        /* scoped variables */ {
            nanogui::ref<ExampleApplication> app = new ExampleApplication();
            app->drawAll();
            app->setVisible(true);
            emscripten_set_main_loop(mainloop, 0,1);
        }

        nanogui::shutdown();
    } catch (const std::runtime_error &e) {
        std::string error_msg = std::string("Caught a fatal error: ") + std::string(e.what());
        #if defined(_WIN32)
            MessageBoxA(nullptr, error_msg.c_str(), NULL, MB_ICONERROR | MB_OK);
        #else
            std::cerr << error_msg << endl;
        #endif
        return -1;
    }

    return 0;
}
