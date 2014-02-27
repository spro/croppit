import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.URL;
import javax.imageio.ImageIO;
import java.util.concurrent.Executors;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.Headers;

// imgscalr does the image processing heavy lifting
// http://github.com/thebuzzmedia/imgscalr
import org.imgscalr.Scalr;

public class Croppit {

    static int PORT = 8050;
    static int THREADS = 10;
    static int DEFAULT_W = 640;
    static int DEFAULT_H = 200;

    public static void main(String[] args) throws Exception {

        // Launch the server on PORT, listening for requests to /crop
        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);
        server.createContext("/crop", new CroppitHandler());
        server.setExecutor(Executors.newFixedThreadPool(THREADS));
        server.start();

        System.out.println("Listening on :" + PORT);

    }

    static class CroppitHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {

            // Parse URL query parameters
            // Expects the query to be in the format "size=size&url=url"
            // Where the size is in the form "500x200" or "100" (square)
            String query = t.getRequestURI().getQuery();
            String[] queryParts = query.split("&");

            String imageURLStr;
            int crop_width;
            int crop_height;

            // ?size=...x...&url=...
            if (queryParts.length == 2) {
                String sizeStr = queryParts[0].split("=")[1];
                String[] sizeParts = sizeStr.split("x");
                if (sizeParts.length == 2) {
                    crop_width = Integer.parseInt(sizeParts[0]);
                    crop_height = Integer.parseInt(sizeParts[1]);
                } else {
                    crop_width = Integer.parseInt(sizeParts[0]);
                    crop_height = Integer.parseInt(sizeParts[0]);
                }
                imageURLStr = queryParts[1].split("=")[1]; 

            // ?url=...
            } else if (queryParts.length == 1) {
                crop_width = DEFAULT_W;
                crop_height = DEFAULT_H;
                imageURLStr = queryParts[0].split("=")[1]; 

            // Invalid request
            } else {
                return;
            }

            // Load image from given URL
            URL imageURL = new URL(imageURLStr);
            BufferedImage img = ImageIO.read(imageURL);

            // Do the sizing and cropping dance

            // Wide crop, fit width first
            if (crop_width > crop_height) {
                img = Scalr.resize(
                    img,
                    Scalr.Method.BALANCED,
                    Scalr.Mode.FIT_TO_WIDTH,
                    crop_width,
                    crop_height,
                    Scalr.OP_ANTIALIAS
                );
                img = Scalr.crop(
                    img,
                    0,
                    (img.getHeight()-crop_height)/2,
                    crop_width,
                    crop_height
                );

            // Tall crop, fit height first
            } else {
                img = Scalr.resize(
                    img,
                    Scalr.Method.BALANCED,
                    Scalr.Mode.FIT_TO_HEIGHT,
                    crop_width,
                    crop_height,
                    Scalr.OP_ANTIALIAS
                );
                img = Scalr.crop(
                    img,
                    (img.getWidth()-crop_width)/2,
                    0,
                    crop_width,
                    crop_height
                );
            }

            // Get size of resulting image by writing to byte stream
            ByteArrayOutputStream tmp = new ByteArrayOutputStream();
            ImageIO.write(img, "jpg", tmp);
            Integer img_length = tmp.size();

            // Set response headers
            Headers h = t.getResponseHeaders();
            h.add("Content-Type", "image/jpeg");
            t.sendResponseHeaders(200, img_length);

            // Write response
            OutputStream os = t.getResponseBody();
            os.write(tmp.toByteArray());

            // Clean up
            os.close();
            tmp.close();

        }
    }
}

